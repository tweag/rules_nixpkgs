with import <nixpkgs> { config = {}; overlays = []; };

{ arg_local_file, arg_external_file }:
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
      cp ${arg_local_file} $out/out/arg_local_file
      cp ${arg_external_file} $out/out/arg_external_file
    ''
