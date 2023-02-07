with import ./pkgname.nix;
let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in builtins.getAttr pkgname pkgs

