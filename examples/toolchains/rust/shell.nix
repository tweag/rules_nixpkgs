{ pkgs ? import ./nixpkgs.nix { } }:
with pkgs;
mkShell {
  nativeBuildInputs = [ bazel_5 git nix zlib libiconv ]
    ++ (if stdenv.isDarwin then
      [ darwin.apple_sdk.frameworks.Security ]
    else
      [ ]);
}
