{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShellNoCC { nativeBuildInputs = with pkgs; [ nix bazel_7 ]; }
