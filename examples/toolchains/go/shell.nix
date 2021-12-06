{ pkgs ? import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/21.11.tar.gz";
  sha256 = "162dywda2dvfj1248afxc45kcrg83appjd0nmdb541hl7rnncf02";
}) { } }:

pkgs.mkShell { nativeBuildInputs = [ pkgs.bazel_4 ]; }
