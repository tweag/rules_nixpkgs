let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  src = lock.nodes.nixpkgs.locked;
  nixpkgs =
    assert src.type == "github";
    fetchTarball {
      url = "https://github.com/${src.owner}/${src.repo}/archive/${src.rev}.tar.gz";
      sha256 = src.narHash;
    };
in
import nixpkgs
