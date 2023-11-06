# Exactly one of goAttrPath or goExpr must be set.
# If a custom `goExpr` derivation is provided by the user, we add the `go_version.bzl` file to it.
# Otherwise we create a toolchain based on the `goAttrPath` attribute path from <nixpkgs>

let
  pkgs = import <nixpkgs> {
    config = { };
    overlays = [ ];
  };
in args@{ goAttrPath ? null, goExpr ? null }:
let
  getVersion = s:
    s.version or (throw
      "nix_pkgs_go_configure: the provided go derivation should contain a `version` attribute.");

  bazelGoToolchain = args.goExpr or (let
    goAttr =
      pkgs.lib.attrByPath (pkgs.lib.splitString "." goAttrPath) null pkgs;
  in pkgs.buildEnv {
    name = "bazel-go-toolchain";
    paths = [ goAttr ];
    postBuild = ''
      touch $out/ROOT
      ln -s $out/share/go/{api,doc,lib,misc,pkg,src,go.env} $out/
    '';
  } // {
    version = getVersion goAttr;
  });

  goVersionFile = pkgs.runCommand "bazel-go-toolchain-go-version" { } ''
    mkdir $out
    echo 'go_version = "${getVersion bazelGoToolchain}"' >> $out/go_version.bzl
  '';

in pkgs.symlinkJoin {
  name = "bazel-go-toolchain";
  paths = [ bazelGoToolchain goVersionFile ];
}
