{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShellNoCC { nativeBuildInputs = with pkgs; [ bazel_6 nodejs ]; }
