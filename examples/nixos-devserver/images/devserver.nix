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
