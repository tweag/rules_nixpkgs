{ packages
, nixpkgs ? import <nixpkgs> {}
}:
with nixpkgs;
let
  # `nix-store --realize` will build *all* the outputs of the provided drv file.
  # Since we only want to access to the specified output, we wrap it into a
  # single-output derivation pointing to it.
  wrapOutput = target:
    if !(target ? name) then null else
    symlinkJoin {
      name = target.name;
      paths = [ target ];
    };

  # Returns the path to a `.drv` file corresponding to the provided derivation
  evaluateElement = x:
    let result = builtins.tryEval ((wrapOutput x).drvPath or null); in
    if result.success == true then result.value else null;
in
(builtins.mapAttrs (_: evaluateElement) (packages nixpkgs))

