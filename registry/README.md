# Local Bazel Registry for rules\_nixpkgs modules

This [local Bazel registry][registry] is only intended for testing and local
development purposes. The rules\_nixpkgs repository is split into multiple
Bazel modules that may depend on each other. Unfortunately, overrides such as
`local_path_override` are only allowed in the main module, and command-line
configuration like `--override_module` is difficult to configure correctly
since it does not support relative paths. Instead, we use a local registry.

[registry]: https://bazel.build/external/registry
