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

## rules\_nixpkgs Module Extensions

Before Bzlmod rules\_nixpkgs defined Bazel [repository rules][repository-rule]
to import nixpkgs repositories and Nix packages and toolchains into a Bazel
project. Users invoked these in their project's WORKSPACE file, either
directly, or through repository macros (Starlark functions).

With Bzlmod repository rules can no longer be invoked directly by a user in the
MODULE.bazel file that defines a Bazel module. Instead, users must invoke a
[Module extension][module-extension] and define tags for the dependencies they
wish to import.

This design document defines the required functionality and the given
constraints and uses these to develop which module extensions and tags are
required, and API they should provide.

## Principles

Follow the principles of modular, simple, and composable software:

* *modular* - define independently useful and reusable parts.
* *simple* - keep components focused on a single purpose.
* *composable* - enable interoperability between the system's parts.

The module extensions should align with Bazel best-practices.

The module extensions should support the use-cases that the previous repository
rule based API supported and should strive to minimize migration cost.
[bzlmod]: https://bazel.build/external/overview#bzlmod
[module-extension]: https://bazel.build/external/extension
[repository-rule]: https://bazel.build/extending/repo
[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-path]: https://nixos.org/manual/nix/stable/language/values.html#type-path
