# This will take many hours to build. Caching this somewhere is recommended.
let
  targetSystem = "x86_64-linux";
  og = import <nixpkgs> {};
  nixpkgs = import <nixpkgs> {
    buildSystem = builtins.currentSystem;
    hostSystem = targetSystem;
    crossSystem = {
      config = targetSystem;
    };
    crossOverlays = [
      (self: super: {
        # Apparently this is a hacky way to extend llvmPackages, but whatever
        llvmPackages_11 = super.llvmPackages_11.extend (final: prev: rec {
          libllvm = prev.libllvm.overrideAttrs (old: {
            # We need to override LDFLAGS because it puts non-Darwin compatible flags,
            # so remove the old flags, and also explicitly tell the compiler where to
            # find libcxxabi. Not sure why we need to do this.
            LDFLAGS = "-L ${super.llvmPackages_11.libcxxabi}/lib";
            # We need to make sure cctools is available because darwin code signing needs it
            # in your $PATH.
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [og.darwin.cctools];
          });
          libclang = prev.libclang.override {
            inherit libllvm;
          };
          libraries = super.llvmPackages_11.libraries;
        });
      })
    ];
  };
  # this will use linux binaries from binary cache, so no need to build those
  pkgsLinux = import <nixpkgs> {
    config = {};
    overlays = [];
    system = targetSystem;
  };
  packages = [pkgsLinux.boost175 pkgsLinux.zlib pkgsLinux.bash nixpkgs.stdenv.cc.cc.lib];
  closure = with og; builtins.toString (lib.strings.splitString "\n" (builtins.readFile "${closureInfo {rootPaths = packages;}}/store-paths"));
in
  og.buildEnv {
    name = "closure";
    paths = [];
    buildInputs = packages;
    postBuild = "tar -cf $out/closure.tar ${closure}";
  }
