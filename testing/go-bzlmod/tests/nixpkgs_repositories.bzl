load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_local_repository")
load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")
load("@rules_nixpkgs_go//:go.bzl", "nixpkgs_go_configure")

_PATCHED_CC = """\
{ ccPkgs ? import <nixpkgs> { config = { }; overlays = [ ]; }
}:

let
  pkgs = ccPkgs.buildPackages;
  stdenv = ccPkgs.stdenv;
  # The original `postLinkSignHook` from nixpkgs assumes `codesign_allocate` is
  # in the PATH which is not the case when using our cc_wrapper. Set
  # `CODESIGN_ALLOCATE` to an absolute path here and override the hook for
  # `darwinCC` below.
  postLinkSignHook =
    with pkgs; writeTextFile {
      name = "post-link-sign-hook";
      executable = true;

      text = ''
        CODESIGN_ALLOCATE=${darwin.cctools}/bin/codesign_allocate \
          ${darwin.sigtool}/bin/codesign -f -s - "$linkerOutput"
      '';
    };
  darwinCC =
    # Work around https://github.com/NixOS/nixpkgs/issues/42059.
    # See also https://github.com/NixOS/nixpkgs/pull/41589.
    pkgs.wrapCCWith rec {
      cc = stdenv.cc.cc;
      bintools = stdenv.cc.bintools.override { inherit postLinkSignHook; };
      extraBuildCommands = with pkgs.darwin.apple_sdk.frameworks; ''
        sed -i.bak 's#--tmpdir cc-params.XXXXXX#"''${TMPDIR:-/tmp}/cc-params.XXXXXX"#' $out/bin/cc
        echo "-Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
        echo "-Wno-elaborated-enum-base" >> $out/nix-support/cc-cflags
        echo "-isystem ${pkgs.llvmPackages.libcxx.dev}/include/c++/v1" >> $out/nix-support/cc-cflags
        echo "-isystem ${pkgs.llvmPackages.clang-unwrapped.lib}/lib/clang/${cc.version}/include" >> $out/nix-support/cc-cflags
        echo "-F${CoreFoundation}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${CoreServices}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${Security}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${Foundation}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-L${pkgs.llvmPackages.libcxx}/lib" >> $out/nix-support/cc-cflags
        echo "-L${pkgs.llvmPackages.libcxxabi}/lib" >> $out/nix-support/cc-cflags
        echo "-L${pkgs.libiconv}/lib" >> $out/nix-support/cc-cflags
        echo "-L${pkgs.darwin.libobjc}/lib" >> $out/nix-support/cc-cflags
        echo "-resource-dir=${pkgs.stdenv.cc}/resource-root" >> $out/nix-support/cc-cflags
      '';
    };
in
pkgs.buildEnv (
  let
    cc = if stdenv.isDarwin then darwinCC else stdenv.cc;
  in
  {
    name = "bazel-${cc.name}-wrapper";
    # XXX: `gcov` is missing in `/bin`.
    #   It exists in `stdenv.cc.cc` but that collides with `stdenv.cc`.
    paths = [ cc cc.bintools ] ++ pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.darwin.cctools;
    pathsToLink = [ "/bin" ];
    passthru = {
      inherit (cc) isClang targetPrefix;
      orignalName = cc.name;
    };
  }
)
"""

def nixpkgs_repositories(*, bzlmod):
    nixpkgs_local_repository(
        name = "nixpkgs",
        nix_file = "//:nixpkgs.nix",
        nix_file_deps = ["//:flake.lock"],
    )

    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
        register = not bzlmod,
        nix_file_content = _PATCHED_CC,
    )

    nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = "jdk11.home",
        repository = "@nixpkgs",
        toolchain = True,
        register = not bzlmod,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "11",
    )

    nixpkgs_go_configure(
        sdk_name = "nixpkgs_go_sdk",
        repository = "@nixpkgs",
        register = not bzlmod,
    )
