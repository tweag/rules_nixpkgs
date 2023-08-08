def nix_pkg(module_name, name, label):
    # This is a WORKSPACE mode replacement for @nixpkgs_packages.
    return Label("@" + name).relative(label)
