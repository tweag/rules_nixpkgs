let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) lib poetry2nix python3 runCommand;

  args = {
    python = python3;
    pyproject = ./pyproject.toml;
    poetrylock = ./poetry.lock;
    preferWheels = true;
  };
  env = poetry2nix.mkPoetryEnv args;
  packages = poetry2nix.mkPoetryPackages args;
  isWheelCffi = env.python.pkgs.cffi.src.isWheel;
  isWheelPandas = env.python.pkgs.pandas.src.isWheel;
in
  assert isWheelCffi; assert isWheelPandas;
  {
    inherit packages env;
    python = packages.python;
    pkgs = packages.poetryPackages;
  }
