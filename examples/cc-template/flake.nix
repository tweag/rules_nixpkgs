{
  description = "Flake utils demo";

  outputs = { self, nixpkgs }:
  let 
    system = "x86_64-linux";
    pkgs = (import nixpkgs { inherit system; config.allowUnfree = true; });
    in {
      devShell.${system} = pkgs.mkShellNoCC {
        buildInputs = with pkgs; [
          buildifier
          bazel_5
          buildozer
        ];
      };
    };
}
