with import <nixpkgs> { config = {}; overlays = []; };

{ arg_local_file, arg_external_file, argstr_local_file, argstr_external_file }:
let
  inherit (attrs) nixpkgs_json nixpkgs_nix;
  # replace by lib.path.append once released
  # https://github.com/NixOS/nixpkgs/pull/208887
  path_append = p: s: p + ("/" + s);
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
      cp ${path_append ../. argstr_local_file} $out/out/argstr_local_file
      cp ${path_append ../. argstr_external_file} $out/out/argstr_external_file
    ''
