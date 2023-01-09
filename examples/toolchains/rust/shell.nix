{ pkgs ? import ./nixpkgs.nix { } }:
with pkgs;
mkShell { nativeBuildInputs = [ bazel_5 git nix zlib ]; }
