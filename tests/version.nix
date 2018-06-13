with import ./minor.nix;
with import ./major.nix;

import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/${major}.${minor}.tar.gz") {}

