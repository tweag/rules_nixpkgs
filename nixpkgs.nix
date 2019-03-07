let
  nixpkgsRev = "a5aca72f93715ea7a44e47028ed1404ec1efb525";
  nixpkgsSha256 = "1k0ggn431z2aj4snq815w788qz4cw3ajs2wgnbhl0idqzqq6gm36";
  nixpkgs = fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/${nixpkgsRev}.tar.gz";
    sha256 = nixpkgsSha256;
  };
in
import nixpkgs
