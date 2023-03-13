let
  nixpkgs = import <nixpkgs> {};
  mach-nix = import (nixpkgs.fetchFromGitHub {
    owner = "DavHau";
    repo = "mach-nix";
    rev = "f60b9833469adb18e57b4c9e8fc4804fce82e3da";
    hash = "sha256-LGFLMTf9gEPYzLuny3idKQOGiZFVhmjR2VGvio4chMI=";
  }) {
    # ** Extremely important! **
    # You want to use the same python version as your main nixpkgs.
    # Bazel does not enforce this, and it will fail for binary packages.
    #pkgs = nixpkgs; # broken with this version of mach-nix
    python = "python310";
    pypiDataRev = "cc1357c73b483fdec3091ea782aafc86a6a79fe1";
    pypiDataSha256 = "042gn8m6iw7kcwn5qzdqxvhw5q1k6y3h1jww0r746mfmi0qn5i80";
  };
  pythonWithPackages = mach-nix.mkPython {
    requirements = builtins.readFile ./requirements.txt;
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
