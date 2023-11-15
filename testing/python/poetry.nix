let
  nixpkgs = import <nixpkgs> { };
  poetry2nix = import <poetry2nix> { pkgs = nixpkgs; };
  inherit (nixpkgs) python3;

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
