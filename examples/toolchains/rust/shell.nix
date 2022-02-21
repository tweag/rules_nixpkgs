{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShell { nativeBuildInputs = [ pkgs.bazel_4 ]; }
