{ ... }:
let
  # nixpkgs-unstable of 25-06-2020
  sha256 = "0ir3rk776wldyjz6l6y5c5fs8lqk95gsik6w45wxgk6zdpsvhrn5";
  rev = "2cd2e7267e5b9a960c2997756cb30e86f0958a6b";
  pkgs = import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  }) {};
in
{
  inherit pkgs;

  toolchain_variables = pkgs.callPackage ./autogen/toolchains {};


  repro = pkgs.mkShell {
    buildInputs = [ pkgs.bazel ];

    shellHook = ''
      bazel build @toolchain_variables//:variables.bzl && cat $(find -L | grep variables.bzl | grep -v nix-out-link)
      exit
    '';
  };

  clean = pkgs.mkShell {
    buildInputs = [ pkgs.bazel ];

    shellHook = ''
      bazel clean --expunge
      exit
    '';
  };
}


/*

For a reproduction.

runs:

$ nix-shell build/nix -A repro

You should see something like `foo = "12"`.

Change the value in build/nix/autogen/toolchains/default.nix to something different.

runs:

$ nix-shell build/nix -A repro

You should see "12". This is a caching issue, the expected value is what you set in the file.

If you clean and re-run using:

$ nix-shell build/nix -A clean
$ nix-shell build/nix -A repro

You will see your value.
*/
