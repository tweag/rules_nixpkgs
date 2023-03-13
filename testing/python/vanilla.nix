let
  nixpkgs = import <nixpkgs> {};
  filterFun = ps: [ ps.flask ];
  pythonWithPkgs = nixpkgs.python310.withPackages filterFun;
in {
  python = pythonWithPkgs.python;
  pkgs = filterFun pythonWithPkgs.pkgs;
}
