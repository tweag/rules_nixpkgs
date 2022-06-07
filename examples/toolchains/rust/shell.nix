{ pkgs ? import ./nixpkgs.nix { } }:

with pkgs;
mkShell { 
  nativeBuildInputs = [
    bazel_4 
    git
    nix
    zlib
  ];
}
