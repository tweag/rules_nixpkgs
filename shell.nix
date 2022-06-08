{ pkgs ? import ./core/nixpkgs.nix { config = {}; overlays = []; } }:

with pkgs;

mkShell {
  buildInputs = [
    bazel_5
    cacert
    gcc
    nix
    git
  ];
}
