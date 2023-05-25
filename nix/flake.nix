{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, fenix, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells."x86_64-linux".default = pkgs.mkShellNoCC
        {
          packages = [
            pkgs.bazel-buildtools
            pkgs.hugo
            pkgs.git
            pkgs.rustfmt
          ];
        };
    };
}
