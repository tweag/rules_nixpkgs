Python Toolchain Example
========================

This is an example Python project with modules that uses `rules_python`. Providing Python modules without Nix is currently not supported.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```

To specify Python version or modules, change the `python3_attribute_path` parameter in the `nixpkgs_python_configure` call in the `WORKSPACE` file.
