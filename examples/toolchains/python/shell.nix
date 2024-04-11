{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShellNoCC { nativeBuildInputs = [ pkgs.nix pkgs.bazel_6 ]; }
