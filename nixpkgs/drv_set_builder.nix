{ packages
, nixpkgs ? import <nixpkgs> {}
}:
with nixpkgs;
let
  # Returns the path to a `.drv` file corresponding to the provided derivation
  evaluateElement = x:
    let result = builtins.tryEval (x.drvPath + "!" + x.outputName); in
    if result.success == true then result.value else null;
in
(builtins.mapAttrs (_: evaluateElement) (packages nixpkgs))

