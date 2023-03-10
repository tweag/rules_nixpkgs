{
  # A file to be later `import`ed, and providing two attributes: 
  # - `python`: used to obtain the valie of `sitePackages`
  # - `pkgs`: a set of python packages whose closure will be exposed in the
  #   generated json file, and consumed by `nixpkgs_python_repository` rule.
  nix_file
}:
let
  nixpkgs = import <nixpkgs> {};
  pythonExpr = import nix_file;
  inherit (pythonExpr) python pkgs;

  isPythonModule = drv: drv ? pythonModule && drv ? pythonPath;
  filterPythonModules = builtins.filter isPythonModule;

  # Ensure the dependency list is unique, otherwise bazel complains about
  # duplicate names in the generated python_module() rule
  unique = list: builtins.attrNames (builtins.listToAttrs (builtins.map (x: {
    name = x;
    value = null;
  }) list));

  # Build the list of python modules from the initial set in `pkgs`.
  # Each key is the package name, and the value is the derivation itself.
  toClosureFormat = builtins.map (drv: {
    key = drv.pname;
    value = drv // { _pythonModules = filterPythonModules drv.propagatedBuildInputs; };
  });
  startSet = toClosureFormat pkgs;
  closure = builtins.genericClosure {
    inherit startSet;
    operator = item: toClosureFormat (filterPythonModules item.value.propagatedBuildInputs);
  };

  # Using the information generated above, map the package information into
  # a list, described in the Output description at the top of this file.
  packages = builtins.map ({key, value}: {
    name = key;
    store_path = "${value}/${python.sitePackages}";
    deps = unique (builtins.map (dep: dep.pname) value._pythonModules);
  }) closure;
in
  (nixpkgs.writeTextFile {
    name = "python-requirements";
    destination = "/requirements.json";
    text = builtins.toJSON packages;
  }) // {
    inherit python pkgs;
  }
