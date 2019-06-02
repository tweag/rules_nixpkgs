{ pkgs ? import ./nixpkgs.nix { config = {}; } }:

with pkgs;

mkShell {
  buildInputs = [
    bazel
    gcc
    nix
  ];
}
