{ packages
, nixpkgs ? import <nixpkgs> {}
}:
with nixpkgs;
let
  # Returns the path to a `.drv` file corresponding to the provided derivation
  evaluateElement = x:
    let result = builtins.tryEval (
      if builtins.isAttrs x && x ? drvPath && x ? outputName then
      x.drvPath + "!" + x.outputName
      else null
      );
    in
    if result.success == true then result.value else null;
in
(lib.mapAttrs (name: value: (evaluateElement value)) (packages nixpkgs))

