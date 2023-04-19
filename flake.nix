{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, fenix, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells."x86_64-linux".default = pkgs.mkShellNoCC
        {
          packages = [
            pkgs.hugo
            pkgs.git
          ];
        };
    };
}
