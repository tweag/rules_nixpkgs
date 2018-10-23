{ pkgs ? import ./nixpkgs-pin.nix {} }:

with pkgs;

mkShell {
  buildInputs = [
    bazel
    gcc
    nix
  ];
}
