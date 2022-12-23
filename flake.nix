{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
    flake-utils.url = github:numtide/flake-utils;
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        bazel = if pkgs.lib.strings.hasSuffix "-darwin" system then 
          pkgs.bazel_6.override { runJdk = pkgs.zulu; }
        else
          pkgs.bazel_6;
      in
      {
        devShells.default = with pkgs; mkShell {
          name = "rules_nixpkgs_shell";
          packages = [ bazel bazel-buildtools cacert gcc nix git ];
        };
      });
}
