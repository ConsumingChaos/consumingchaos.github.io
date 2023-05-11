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
