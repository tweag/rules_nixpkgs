let
  # nixpkgs-unstable as of 2019-04-25
  nixpkgsRev = "0620e0fdbf4";
  nixpkgsSha256 = "046l2c83s568c306hnm8nfdpdhmgnbzgid354hr7p0khq3jx3lhf";
  nixpkgs = fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/${nixpkgsRev}.tar.gz";
    sha256 = nixpkgsSha256;
  };
in
import nixpkgs
