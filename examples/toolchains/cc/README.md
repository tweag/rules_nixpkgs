C++ Toolchain Example
=====================

This is an example C++ project that uses `rules_cc`. It should build and run both with or without Nix installed.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```

To run the example without Nix, make sure you have Bazel installed, and issue the following command:
```
bazel run :hello
```
This non-Nix example will look for the C++ toolchain on the PATH.
