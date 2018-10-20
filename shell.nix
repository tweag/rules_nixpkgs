{ pkgs ? import ./nix/default.nix {} }:

with pkgs;

mkShell {
  buildInputs = [
    bazel
    gcc
    nix
  ];
}
