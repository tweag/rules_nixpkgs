{ pkgs ? import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/7f9b6e2babf232412682c09e57ed666d8f84ac2d.tar.gz";
  sha256 = "03nb8sbzgc3c0qdr1jbsn852zi3qp74z4qcy7vrabvvly8rbixp2";
}) { } }:

pkgs.mkShell { nativeBuildInputs = [ pkgs.bazel_5 ]; }
