{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell { nativeBuildInputs = [ pkgs.bazel_4 ]; }
