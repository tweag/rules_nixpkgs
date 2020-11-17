with import <nixpkgs> { config = {}; overlays = []; };

{ local_file, external_file }:
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
      cp ${local_file} $out/out/local_file
      cp ${external_file} $out/out/external_file
    ''
