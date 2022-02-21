let
  # nixpkgs-unstable as of 2021-02-19
  spec = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
  nixpkgs = fetchTarball {
    url = "https://github.com/${spec.owner}/${spec.repo}/archive/${spec.rev}.tar.gz";
    sha256 = spec.sha256;
  };
in
import nixpkgs
