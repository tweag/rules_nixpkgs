Rust Toolchain Example
======================

This is an example Rust project that uses `rules_rust`.
It showcases the integration nix, giving concrete example of how to approach project compilation with dependency on OpenSSL library. 

If the Nix package manager is present in the build environment, this example will use Nix to provide the Rust toolchain. 
Otherwise, it will fail (it is possible to make the example run without nix, however it greatly obfuscates the core of the matter).

# Usage

To run the example with Nix, issue the following command:
```
nix-shell --command 'bazel run --config=nix :hello'
```
