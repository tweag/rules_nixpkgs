{ pkgs ? import ./nixpkgs.nix {} }:

with pkgs;

let bazelShell = import ./bazel-shell.nix pkgs; in

bazelShell {
  buildInputs = [
    bazel
    gcc
    nix
    python2
  ];

  BAZEL_PYTHON="${python2}/bin/python";

  bazelRepositories = {
    hello = { path = hello; };
  };

  buildImage = true;
}
