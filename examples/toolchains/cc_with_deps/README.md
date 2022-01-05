C++ With Dependencies Toolchain Example
=======================================

This is an example C++ project with dependencies that uses `rules_cc`.

This example uses the Nix package manager to provide C++ dependencies, and as such only works with Nix installed. Demonstrating other methods of providing C++ dependencies is out of scope of this example.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```
