let
  nixpkgs = import <nixpkgs> {};
  mach-nix = import (nixpkgs.fetchFromGitHub {
    owner = "DavHau";
    repo = "mach-nix";
    rev = "68a85753555ed67ff53f0d0320e5ac3c725c7400";
    hash = "sha256-YIcQtXNQSofFSRDO8Y/uCtXAMguc8HqpY83TstgkH+k=";
  }) { };
  pythonWithPackages = mach-nix.mkPython {
    requirements = builtins.readFile ./requirements.txt;
    # Keep this aligned with whatever nixpkgs.python is in flake.nix.
    python = "python310";
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
