with import <nixpkgs> { config = {}; overlays = []; };

{ attrs, relative_imports }:
let
  inherit (attrs) nixpkgs_json nixpkgs_nix;
in
  runCommand "location-expansion"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      mkdir -p $out/out
      cp ${nixpkgs_json} $out/out/nixpkgs.json
      cp ${nixpkgs_nix} $out/out/nixpkgs.nix
      cp ${relative_imports} $out/out/relative_imports.nix
    ''
