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
              consumingchaos = { };
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
                  networking.hostName = "jleitch";
                };
              }
            ];
          }).config.system.build.toplevel;
        };
    };
}
