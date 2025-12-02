Python Toolchain Example
========================

This is an example Python project with modules that uses `rules_python`.

This example uses the Nix package manager to provide Python packages, and as such only works with Nix installed. Demonstrating other methods of providing Python packages is out of scope of this example.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```

To specify Python version or modules, change the `python3_attribute_path` parameter in the `nixpkgs_python_configure` call in the `extension.bzl` file.
