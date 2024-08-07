{ pkgs ? import ./nixpkgs.nix { } }:
with pkgs;
mkShell {
  nativeBuildInputs = [ bazel_6 cacert git nix zlib libiconv ]
    ++ (lib.optional stdenv.isDarwin [ darwin.apple_sdk.frameworks.Security ]);
}
