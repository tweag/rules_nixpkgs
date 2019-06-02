with import ./pkgname.nix;
let pkgs = import <nixpkgs> { config = {}; }; in builtins.getAttr pkgname pkgs

