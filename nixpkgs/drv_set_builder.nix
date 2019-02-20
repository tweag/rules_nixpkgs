{ packages
, nixpkgs ? import <nixpkgs> {}
}:
with nixpkgs;
let
  # Dummy package which will raise an error when built to replace packages who
  # don't evaluate properly
  evaluationError = name: nixpkgs.runCommand "evaluationError" {} ''
    echo 'Error: Could not instantiate the nix package "${lib.escapeShellArg name}".'
    exit 1
  '';

  # Returns the path to a `.drv` file corresponding to the provided derivation
  evaluateElement = name: x:
    let result = builtins.tryEval (
      if builtins.isAttrs x && x ? drvPath && x ? outputName then
      x.drvPath + "!" + x.outputName
      else (evaluationError name).drvPath
      );
    in
    if result.success == true then result.value else null;
in
(lib.mapAttrs (name: value: (evaluateElement name value)) (packages nixpkgs))

