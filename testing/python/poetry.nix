let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) lib poetry2nix python3 runCommand;

  args = {
    python = python3;
    pyproject = ./pyproject.toml;
    poetrylock = ./poetry.lock;
  };
  env = poetry2nix.mkPoetryEnv args;
  packages = poetry2nix.mkPoetryPackages args;
in {
  inherit packages env;
  python = packages.python;
  pkgs = packages.poetryPackages;
}
