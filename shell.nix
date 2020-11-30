{ pkgs ? import ./nixpkgs.nix { config = {}; overlays = []; } }:

with pkgs;

mkShell {
  buildInputs = [
    bazel
    cacert
    gcc
    nix
    git
    jdk11
  ];
}
