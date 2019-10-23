{ system ? builtins.currentSystem
, pkgs ? import relative_imports/nixpkgs.nix { inherit system; config = {}; overlays = []; }
}:
{ inherit (pkgs) hello; }
