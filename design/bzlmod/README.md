# Design: rules\_nixpkgs Module Extension

Bazel version 6 introduced the new [Bzlmod dependency management
system][bzlmod]. In this system Bazel knows two types of dependencies: Bazel
modules, and tags. Bazel modules are native Bazel projects, such as rules\_go.
Tags are custom types of dependencies defined by [module
extensions][module-extension], such as language specific package manager
dependencies.

rules\_nixpkgs consists of Bazel modules - rules\_nixpkgs\_core,
rules\_nixpkgs\_cc, etc. These modules define Bazel extensions that expose Nix
concepts and functionality to Bazel modules and allow Bazel modules to define
and import Nix repositories, packages, and toolchains.

## rules\_nixkgs Module Separation

rules\_nixpkgs is split into multiple Bazel modules to avoid introducing
excessive transitive dependencies:

One of rules\_nixpkgs's features is to import toolchains from Nix into Bazel
and expose them as drop-in replacements for the corresponding Bazel extension's
toolchains. E.g. rules\_nixpkgs\_cc can import a C/C++ toolchain from Nix that
can be used in place of any other Bazel CC toolchain. To that end
rules\_nixpkgs needs to depend on the corresponding Bazel module to gain access
to the toolchain type label and potentially Bazel rules or macros to define a
functioning toolchain.

Without a split of Bazel modules, rules\_nixpkgs would tend to depend on all
Bazel modules that define language toolchains. Bzlmod does not know optional
dependencies, so any user of rules\_nixpkgs would transitively depend on all
these Bazel modules. To avoid the resulting dependency bloat and likelihood of
version conflicts, rules\_nixpkgs is split into a core module and one module
per language integration.

[bzlmod]: https://bazel.build/external/overview#bzlmod
[module-extension]: https://bazel.build/external/extension
