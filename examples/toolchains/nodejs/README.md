NodeJS Toolchain Example
========================

This is an example NodeJS project with modules that uses `rules_nodejs`.

This example uses the Nix package manager to provide NodeJS packages, and as such only works with Nix installed. Demonstrating other methods of providing NodeJS packages is out of scope of this example.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```

To specify NodeJS version, change the `attribute_path` parameter in the `nixpkgs_nodejs_configure` call in the `WORKSPACE` file.
