{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShellNoCC {
  nativeBuildInputs = [ pkgs.nix pkgs.bazel_6 ];
  env.BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN = "1";
}
