# This will take many hours to build. Caching this somewhere is recommended.
let
  targetSystem = "x86_64-linux";
  # this will use linux binaries from binary cache, so no need to build those
  pkgsLinux = import <nixpkgs> {
    config = {};
    overlays = [];
    system = targetSystem;
  };
in let
  pkgs = import ./osxcross_cc_pkgs.nix { inherit targetSystem; };
  linuxCC = pkgs.wrapCCWith rec {
    cc = pkgs.llvmPackages_11.clang-unwrapped;
    bintools = pkgs.llvmPackages_11.bintools;
    extraPackages = [pkgsLinux.glibc.static pkgs.llvmPackages_11.libraries.libcxxabi pkgs.llvmPackages_11.libraries.libcxx];
    extraBuildCommands = ''
      echo "-isystem ${pkgs.llvmPackages_11.clang-unwrapped.lib}/lib/clang/${cc.version}/include" >> $out/nix-support/cc-cflags
      echo "-isystem ${pkgsLinux.glibc.dev}/include" >> $out/nix-support/cc-cflags
      echo "-L ${pkgs.llvmPackages_11.libraries.libcxxabi}/lib" >> $out/nix-support/cc-ldflags
      echo "-L ${pkgsLinux.glibc.static}/lib" >> $out/nix-support/cc-ldflags
      echo "-resource-dir=${cc}/resource-root" >> $out/nix-support/cc-cflags
    '';
  };
in
  pkgs.buildEnv (
    let
      cc = linuxCC;
    in {
      name = "bazel-${cc.name}-cc";
      # XXX: `gcov` is missing in `/bin`.
      #   It exists in `stdenv.cc.cc` but that collides with `stdenv.cc`.
      paths = [cc cc.bintools];
      pathsToLink = ["/bin"];
      passthru = {
        inherit (cc) isClang targetPrefix;
        orignalName = cc.name;
      };
    }
  )
