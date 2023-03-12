let
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix";
    ref = "master";
    rev = "f60b9833469adb18e57b4c9e8fc4804fce82e3da";
    narHash = "sha256-LGFLMTf9gEPYzLuny3idKQOGiZFVhmjR2VGvio4chMI=";
  }) {
    # ** Extremely important! **
    # You want to use the same python version as your main nixpkgs.
    # Bazel does not enforce this, and it will fail for binary packages.
    pkgs = import <nixpkgs> {};
  };
  pythonWithPackages = mach-nix.mkPython {
    requirements = builtins.readFile ./requirements.txt;
    providers._default = "nixpkgs";
  };
  python = pythonWithPackages.python;
  # Beloved hacks !
  # Extract the subset of packages that have been requested by mach-nix.
  # By default, python.pkgs contains all the packages known by nixpkgs,
  # plus the onse configured by mach-nix.
  # This retrives the `extraLibs` attribute that mach-nix configured.
  pkgs = (pythonWithPackages.override (old: {
    ignoreCollisions = old.extraLibs;
  })).ignoreCollisions;
in {
  inherit python pkgs;
}
