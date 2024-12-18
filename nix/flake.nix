{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default =
          with pkgs;
          mkShell {
            # do not use Xcode on macOS
            BAZEL_USE_CPP_ONLY_TOOLCHAIN = "1";
            # for nixpkgs cc wrappers, select C++ explicitly (see https://github.com/NixOS/nixpkgs/issues/150655)
            BAZEL_CXXOPTS = "-x:c++";

            name = "rules_nixpkgs_shell";
            buildInputs = lib.optional pkgs.stdenv.isDarwin darwin.cctools;
            packages = [
              bazel_6
              bazel-buildtools
              cacert
              gcc
              nix
              git
              openssh
            ];
          };
      }
    );
}
