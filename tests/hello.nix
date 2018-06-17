with import ./pkgname.nix;
let pkgs = import <nixpkgs> {}; in builtins.getAttr pkgname pkgs

