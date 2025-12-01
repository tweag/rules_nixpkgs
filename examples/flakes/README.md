# bazel-nix-flakes-example

The example is generating a local nixpkgs repository using the `flakes.lock` file already present on
[flakes](https://nixos.wiki/wiki/Flakes) projects.

## Requirements

The nix package manager should be installed with flakes support enabled.

## Running the example

``bash
nix-shell --run "bazel run :hello"
```
