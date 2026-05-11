load("@rules_nixpkgs_core//:nixpkgs.bzl", "run_nix_shell")

run_nix_shell(
   name = "my_shell",
   outputs = ["hello.txt", "bye.txt"],
   cmd = """
         cowsay 'hello nix!' > $1
         cowsay 'bye!' > $2
         """,
   stdenv = "@my_env//:stdenv",
)
