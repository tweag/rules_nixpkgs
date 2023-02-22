# bazel-nix-flakes-example

The example is generating a local nixpkgs repository using the `flakes.lock` file already present on
[flakes](https://nixos.wiki/wiki/Flakes) projects.

## Requirements

The nix package manager should be installed with flakes support enabled.

## Running the example

The local nixpkgs repository can be used by explicitly specifying the generated toolchain.

``bash
nix-shell --run "bazel run --crosstool_top=@nixpkgs_config_cc//:toolchain :hello"
```
