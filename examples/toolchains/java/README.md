Java Toolchain Example
========================

This is an example Java project with modules that uses the builtin Bazel Java rules.

This example uses the Nix package manager to provide the Java toolchain, and as such only works with Nix installed.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```
