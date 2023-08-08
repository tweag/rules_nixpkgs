{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.hello = pkgs.hello;

        # Custom `BUILD.bazel` that resolves `hello` in its non-default location
        packages.hello-with-build-file = with pkgs; runCommandLocal "hello-with-build-file" { } ''
          mkdir --parents $out
          ln -s ${hello}/bin $out/bin-hidden
          ln -s ${hello}/share $out/share-hidden
          echo 'filegroup(name = "bin", srcs = ["bin-hidden/hello"], visibility = ["//visibility:public"])' > $out/BUILD.bazel
        '';
      });
}
