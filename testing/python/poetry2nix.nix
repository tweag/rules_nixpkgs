let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  poetry2nix =
    let
      src = lock.nodes.poetry2nix.locked;
    in
    assert src.type == "github";
    fetchTarball {
      url = "https://github.com/${src.owner}/${src.repo}/archive/${src.rev}.tar.gz";
      sha256 = src.narHash;
    };
in import poetry2nix
