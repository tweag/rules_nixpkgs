{ pkgs ? import ./nixpkgs.nix { config = {}; overlays = []; } }:

with pkgs;

mkShell {
  buildInputs = [
    bazel
    gcc
    nix
  ];
}
