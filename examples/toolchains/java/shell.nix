{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShellNoCC {
  nativeBuildInputs = [ pkgs.nix pkgs.bazel_7 pkgs.jdk24 ];
  env.BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN = "1";
}
