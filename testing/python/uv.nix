let
  nixpkgs = import <nixpkgs> { };
  inherit (nixpkgs) lib;

  pyproject-nix = import (import <pyproject-nix>) { inherit lib; };
  uv2nix' = import (import <uv2nix>) { inherit lib; pyproject-nix = pyproject-nix; };
  build-system-pkgs = import (import <build-system-pkgs>) {
    inherit lib;
    uv2nix = uv2nix';
    pyproject-nix = pyproject-nix;
  };

  workspace = uv2nix'.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  uvLock = builtins.fromTOML (builtins.readFile ./uv.lock);
  depsByName = builtins.listToAttrs (map (
    pkg: {
      name = pkg.name;
      value = map (dep: dep.name) (pkg.dependencies or [ ]);
    }
  ) uvLock.package);
  projectPkg = builtins.head (builtins.filter (pkg: (pkg.source or { }) ? virtual) uvLock.package);
  roots = builtins.listToAttrs (map (depName: { name = depName; value = [ ]; }) (depsByName.${projectPkg.name} or [ ]));

  python = nixpkgs.python3;

  # package_set_to_json.nix expects pythonModule/pythonPath and follows
  # propagatedBuildInputs for dependency edges. Ensure both are present,
  # including deps from uv.lock.
  compatOverlay = pkgsFinal: pkgsPrev:
    lib.mapAttrs (
      name: value:
        if lib.isDerivation value then
          value // {
            pythonModule = python;
            pythonPath = "${value}/${python.sitePackages}";
            propagatedBuildInputs =
              let
                baseDeps = map (
                  dep:
                  if dep ? pname && pkgsFinal ? ${dep.pname} then pkgsFinal.${dep.pname}
                  else dep
                ) (value.propagatedBuildInputs or [ ]);
                lockDeps = map (
                  depName:
                  if pkgsFinal ? ${depName} then pkgsFinal.${depName}
                  else null
                ) (if depsByName ? ${name} then depsByName.${name} else [ ]);
              in
              lib.unique (baseDeps ++ builtins.filter (dep: dep != null) lockDeps);
          }
        else
          value
    ) pkgsPrev;

  pythonSet =
    (nixpkgs.callPackage pyproject-nix.build.packages { inherit python; })
    .overrideScope (
      lib.composeManyExtensions [
        build-system-pkgs.wheel
        overlay
        compatOverlay
      ]
    );
in
{
  inherit python;
  pkgs = pythonSet.resolveVirtualEnv roots;
}
