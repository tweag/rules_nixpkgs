C++ With Dependencies Toolchain Example
=======================================

This is an example C++ project with dependencies that uses `rules_cc` and the Nix package manager.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```

Building this example without Nix is currently not supported.
