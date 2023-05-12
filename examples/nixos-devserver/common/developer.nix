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
