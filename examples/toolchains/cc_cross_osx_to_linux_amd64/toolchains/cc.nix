# We need to write a fancy nix file to handle the CC compiler due to OSX: https://github.com/tweag/rules_nixpkgs/issues/368
# What this file is basically saying is: if OSX, change the CXX compiler to use a bunch of Apple frameworks, LLVM libs,
# libc++ instead of libstdc++, and some additional compiler flags to ignore some warnings, otherwise, just use clang
let
  pkgs = import <nixpkgs> { };
in
let
  inherit (pkgs) clang;

  # The original `postLinkSignHook` from nixpkgs assumes `codesign_allocate` is
  # in the PATH which is not the case when using our cc_wrapper. Set
  # `CODESIGN_ALLOCATE` to an absolute path here and override the hook for
  # `darwinCC` below.
  postLinkSignHook = with pkgs;
    writeTextFile {
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
      cc = clang;
      bintools = pkgs.stdenv.cc.bintools.override { inherit postLinkSignHook; };
      extraBuildCommands = with pkgs.darwin.apple_sdk.frameworks; ''
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
  linuxCC = pkgs.wrapCCWith rec {
    cc = clang;
    bintools = pkgs.stdenv.cc.bintools;
    extraPackages = [ pkgs.glibc.static ];
    extraBuildCommands = ''
      echo "-isystem ${pkgs.llvmPackages.clang-unwrapped.lib}/lib/clang/${cc.version}/include" >> $out/nix-support/cc-cflags
      echo "-L ${pkgs.glibc.static}/lib" >> $out/nix-support/cc-ldflags
      echo "-resource-dir=${cc}/resource-root" >> $out/nix-support/cc-cflags
    '';
  };
in
pkgs.buildEnv (
  let
    cc =
      if pkgs.stdenv.isDarwin
      then darwinCC
      else linuxCC;
  in
  {
    name = "bazel-nixpkgs-cc";
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
