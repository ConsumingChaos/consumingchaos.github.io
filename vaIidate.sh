#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

(cd "examples/nixos-devserver" && nix flake check)

for example in nix-bazel-cross-compiling cross-compiled-bevy
do
  (cd "examples/${example}" && eval "$(direnv export bash)" && bazel build //:${example})
done
