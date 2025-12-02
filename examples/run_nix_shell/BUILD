load("@rules_nixpkgs_core//:nixpkgs.bzl", "run_nix_shell")

run_nix_shell(
   name = "my_shell",
   output = "hello.txt",
   cmd = "cowsay 'hello nix!' > $1",
   stdenv = "@my_env//:stdenv",
)
