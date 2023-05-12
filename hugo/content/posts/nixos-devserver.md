---
title: NixOS DevServer
date: 2023-05-11T18:00:00-07:00
tags:
  - nix
  - nixpkgs
  - devserver
  - vscode
  - remote
---

**Code: <https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nixos-devserver>**

# Motivation

- Remote development makes it easy to onboard new developers and provide consistent hardware and operating system, while still allowing individual choice in local hardware.
- Provides the ability to fluidly transition across devices, offices, etc. and pick up exactly where you left off. I love being able to just lock my desktop, grab the laptop, head to the couch, and resume whatever I was working on without needing to do anything to synchronize my workspace.
- Offloads CPU intensive tasks to another computer, so your local machine gets to run cool, quiet, and much longer on battery in the case of a laptop.

# NixOS

I've been a interested in Nix/NixOS ever since I first became aware of it a few years ago. "Declarative, deterministic/reproducible, and content addressable" are all keywords that resonate with me, but I didn't have a concrete usage to motivate me to dig in. Earlier this year, both [matklad](https://matklad.github.io/) and [Amos](https://fasterthanli.me/) published some blog posts involving Nix and that inspired me to to finally devote the time to learning Nix/NixOS.

The big upside to NixOS (at least to me) is the promise of declaratively managing a fleet of machines. This sounds like a dream come true, and so far my experiences, after the somewhat steep learning curve, have lived up to that! There's a small caveat, which is to provision a new machine, I need to boot off of the NixOS Live CD, set up `authorized_keys` for `root`, and then run [bootstrap.sh](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nixos-devserver/bootstrap.sh). A potential future improvement is using [nixos-generators](https://github.com/nix-community/nixos-generators) to generate an already set up VM image instead of needing to run the bootstrap script. Once things were up and running, I've had no issues since, and the small configuration changes I've needed to make have been a breeze. During the initial iteration of setting up users and `authorized_keys_command`, I may have locked myself out a few times and needed to use the NixOS Live CD to fix things and re-run [nixos-install](https://nixos.org/manual/nixos/stable/index.html#ch-installation), but such is life 😅

## Nix Flake Setup

My setup involves two separate Nix Flakes, one local per machine and one shared across all machines on GitHub. The local Nix Flake which is responsible for providing its hostname and any other machine specific configuration, referencing the appropriate machine image from the shared Nix Flake, and injecting any secrets (to avoid keeping them on GitHub). The shared Nix Flake is responsible for everything else.

## Local Nix Flake

The local Nix Flake references the shared Nix Flake on GitHub, references the `module` corresponding to the machine image, and then overlays `configuration.nix` and `secrets.nix`. Given that my shared Nix Flake repository is private, in order for the machines to have access, they need a GitHub token. For this purpose, I made a GitHub Personal Access Token scoped to just that repoistory with read permissions. For ease of bootstrapping, I made the decision to embed that token in `bootstrap.sh` which means that there is a secret "exposed" in GitHub. However to read that secret, you would need to have read access to the repo, to read a secret that grants... read access to the repo. This is something that could be rectified with the `nixos-generators` approach mentioned above plus manually providing the token in `secrets.nix`.

`/etc/nixos/flake.nix` (normally created by `bootstrap.sh`):

```nix
{
  description = "<machine description>";

  inputs = {
    consumingchaos.url = github:ConsumingChaos/consumingchaos.github.io?dir=examples/nixos-devserver;

    nixpkgs.follows = "consumingchaos/nixpkgs";
  };

  outputs = { self, nixpkgs, consumingchaos }: {
    nixosConfigurations."<hostname>" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        consumingchaos.nixosModules."x86_64-linux"."<image name>"
        ./configuration.nix
        ./secrets.nix
      ];
    };
  };
}
```

`/etc/nixos/configuration.nix` (normally created by `bootstrap.sh`, note `<hostname>` and `<GitHub token>`):

```nix
{ config, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "<hostname>";

  # Nix Settings
  nix.settings = {
    access-tokens = [ "github.com=<GitHub token>" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  system.stateVersion = "22.11";
}
```

`/etc/nixos/secrets.nix` (a key/value list of secrets, manually populated after bootstrapping):

```nix
{ config, pkgs, ... }:
{
  config = {
    consumingchaos = {
      "<secret name>" = "<secret value>";
      ...
    };
  };
}
```

## Shared Nix Flake

The shared Nix Flake defines the list of machine images and sets up some basic checks to validate the images. Without specifying the final derivation`nix flake check` doesn't know that the image modules represent a NixOS system and can't actually validate the configuration. The final derivation in this case is `nixpkgs.lib.nixosSystem { ... }).config.system.build.toplevel`, so I create a fake set of the local Nix Flake modules and mimic the local Nix Flake setup in the check.

```nix
{
  description = "NixOS Infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    {
      nixosModules."x86_64-linux" =
        {
          devserver = (import ./images/devserver.nix inputs);
          ...
        };

      checks."x86_64-linux" =
        let
          nixosModules = self.nixosModules."x86_64-linux";
          hardwareModule = {
            config = {
              boot.isContainer = true;
              system.stateVersion = "22.11";
            };
          };
          secretsModule = {
            config = {
              consumingchaos = {
                "<secret name>" = "<secret value>";
                ...
              };
            };
          };
        in
        {
          devserver = (nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              nixosModules.devserver
              hardwareModule
              secretsModule
              {
                config = {
                  networking.hostName = "<hostname>";
                };
              }
            ];
          }).config.system.build.toplevel;
          ...
        };
    };
}
```

The actual machine images themselves are quite simple to follow and why, aside from the learning curve, working with NixOS is wonderful. For example, my DevServer is comprised of the following Nix modules. Note that due to NixOS not having a global loader, the Node binary installed by VSCode for VSCode Server requires patching in order to support VSCode Remote SSH. See [nixos-vscode-server](https://github.com/nix-community/nixos-vscode-server) for more info.

`images/devserver.nix` (DevServer NixOS image):

```nix
{ vscode-server, ... }@inputs:
{ lib, config, pkgs, ... }:
let
  users = import ../common/users.nix;
in
{
  # Import modules shared with other images and third-party
  # `vscode-server` module that patches VSCode Remote SSH
  # to work on NixOS.
  imports = [
    (import ../common/base.nix inputs)
    (import ../common/developer.nix inputs)
    vscode-server.nixosModule
  ];

  config = {
    # Hostname is required to match the user's name in this case.
    consumingchaos = {
      user = config.networking.hostName;
      authorizedKeysUsers = [ config.networking.hostName ];
    };

    # Additional packages to install just for DevServers.
    environment.systemPackages = [
      pkgs.gh
    ];

    home-manager.users."${config.consumingchaos.user}" = {
      imports = [
        vscode-server.nixosModules.home
      ];

      # Settings for VSCode Remote SSH sessions.  This particular
      # example causes `git` commands to open in VSCode when run
      # from a VSCode integrated terminal, and the default (usually
      # `nano`) when run from a normal SSH session.
      home.file.".vscode-server/data/Machine/settings.json".text =
        builtins.toJSON {
          "terminal.integrated.env.linux" = {
            "EDITOR" = "code --wait";
          };
      };

      programs.git = {
        enable = true;
        userName = users.userName config.consumingchaos.user;
        userEmail = users.email config.consumingchaos.user;
      };

      services.vscode-server.enable = true;
    };
  };
}
```

`common/users.nix` (list of users and their properties):

```nix
let
  users = {
    "<user>" = {
      userName = "<full name>";
      email = "<email>";
      githubUser = "<GitHub user>";
    };
    ...
  };
in
{
  userName = user: (builtins.getAttr user users).userName;
  email = user: (builtins.getAttr user users).email;
  githubUser = user: (builtins.getAttr user users).githubUser;
}
```

`common/base.nix` (base NixOS configuration applicable to all images):

```nix
{ home-manager, ... }@inputs:
{ lib, config, pkgs, ... }:
with lib;
let
  users = import ./users.nix;
in
{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  options = {
    consumingchaos = {
      user = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          User to create.
        '';
      };

      authorizedKeysUsers = mkOption {
        type = types.listOf types.str;
        description = lib.mdDoc ''
          List of users who's SSH keys will be used
          for `authorized-keys-command`.
        '';
      };
    };
  };

  config = {
    # Instead of using an `authorized_keys` file, reach out to
    # GitHub for a given user's public keys.
    environment.etc."ssh/authorized-keys-command" = {
      mode = "0555";
      text = (
        ''
          #!${pkgs.stdenv.shell}

          if [ "$1" != "${config.consumingchaos.user}" ]; then
            exit 0
          fi

        ''
        + (builtins.concatStringsSep
          "\n"
          (map
            (user: ''
              ${pkgs.curl}/bin/curl --silent --fail \
                https://github.com/${users.githubUser user}.keys
            '')
            config.consumingchaos.authorizedKeysUsers))
      );
    };

    # Packages to be installed on every NixOS machine.
    environment.systemPackages = [
      pkgs.exa
      pkgs.fd
      pkgs.tokei
    ];

    # Enable automatic Nix garbage collection (via systemd service).
    nix.gc = {
      automatic = true;
      options = "--delete-old";
    };

    # Necessary for some packages.
    nixpkgs.config.allowUnfree = true;

    programs.git = {
      enable = true;
      lfs.enable = true;
    };

    # Configure Starship using a config file stored in the repo.
    programs.starship = {
      enable = true;
      settings = lib.importTOML ./starship.toml;
    };

    programs.zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
    };

    security.sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };

    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
      authorizedKeysCommand = "/etc/ssh/authorized-keys-command";
    };

    # Automatically upgrade to the state of the shared Nix Flake
    # on a daily basis.
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      flake = "/etc/nixos";
      flags = [ "--refresh" "--update-input" "consumingchaos" ];
    };

    users.allowNoPasswordLogin = true;
    users.defaultUserShell = pkgs.zsh;
    users.mutableUsers = false;

    users.groups."${config.consumingchaos.user}" = {
      gid = 1000;
    };
    users.users."${config.consumingchaos.user}" = {
      isNormalUser = true;
      uid = 1000;
      group = config.consumingchaos.user;
      extraGroups = [
        "docker"
        "networkmanager"
        "wheel"
      ];
      home = "/home/${config.consumingchaos.user}";
    };

    # Enable Docker and set up automatic garbage collection
    # (via systemd service).
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" "--volumes" "--filter" "until=24h" ];
        dates = "02:00";
      };
    };

    # Home Manager
    home-manager.users."${config.consumingchaos.user}" = {
      home.stateVersion = "22.11";

      # Enable Home Manager managing `~/.zshrc`, etc.
      programs.zsh.enable = true;
    };
  };
}
```

`common/developer.nix` (NixOS configuration applicable to any developer image, like a DevServer or GitHub Actions Runner):

```nix
{ ... }@inputs:
{ lib, config, pkgs, ... }:
with lib;
let
  users = import ./users.nix;
in
{
  config = {
    # Hold on to intermediate files that a developer would otherwise
    # frequently rebuild.
    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
    };

    # Configure `direnv` using a config file stored in the repo.
    home-manager.users."${config.consumingchaos.user}" = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = builtins.readFile ./direnvrc;
      };
    };
  };
}
```

## Updates/Upgrades

As part of the base configuration, all the NixOS machines upgrade to the latest shared Nix Flake every night. However the actual version of [nixpkgs](https://github.com/NixOS/nixpkgs) is pinned based on the shared Nix Flake, not the local one. The upside is this makes `nix flake check` on the shared Nix Flake properly representative because its `flake.lock` is authoritative, but the downside is `nixpkgs` upgrades require pushing a new commit and that's presently a manual process. A potential future improvement would be setting up a daily process to upgrade the Flake dependencies, ensure `nix flake check` passes, and the committing the new `flake.lock`.
