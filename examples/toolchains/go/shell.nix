{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShellNoCC { nativeBuildInputs = [ pkgs.bazel_5 ]; }
