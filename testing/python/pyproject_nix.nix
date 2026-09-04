let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  src = lock.nodes."pyproject-nix".locked;
in
assert src.type == "github";
fetchTarball {
  url = "https://github.com/${src.owner}/${src.repo}/archive/${src.rev}.tar.gz";
  sha256 = src.narHash;
}
