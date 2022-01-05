Go Toolchain Example
====================

This is an example Go project that uses `rules_go`.

If the Nix package manager is present in the build environment, this example will use Nix to provide the Go toolchain. Otherwise, it will use the toolchain provided by `rules_go` and not rely on Nix at all.

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```

To run the example without Nix, make sure you have Bazel installed, and issue the following command:
```
bazel run :hello
```
