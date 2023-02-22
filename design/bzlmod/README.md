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
rules\_nixpkgs needs to depend on the corresponding Bazel module, e.g.
`rules_cc`, to gain access to the toolchain type label and potentially Bazel
rules or macros to define a functioning toolchain.

Without a split of Bazel modules, rules\_nixpkgs would tend to depend on all
Bazel modules that define language toolchains. Bzlmod does not know optional
dependencies, so any user of rules\_nixpkgs would transitively depend on all
these Bazel modules. To avoid the resulting dependency bloat and likelihood of
version conflicts, rules\_nixpkgs is split into a core module and one module
per language integration, such that users only incur transitive dependencies on
relevant Bazel extensions, e.g. only `rules_cc` for C/C++ users.

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
required, and what API they should provide.

## Principles

Follow the principles of modular, simple, and composable software:

* *modular* - define independently useful and reusable parts.
* *simple* - keep components focused on a single purpose.
* *composable* - enable interoperability between the system's parts.

The module extensions should align with Bazel best-practices.

The module extensions should support the use-cases that the previous repository
rule based API supported and should strive to minimize migration cost.

## Requirements

### Nix Repositories

Support the import of Nix repositories, i.e. collections of files containing
Nix expressions, most commonly [nixpkgs].

* Import from
  * Local file, e.g. `nixpkgs.nix`, with optional file dependencies.
  * HTTP URL, e.g. GitHub source archive.\
    (The current `nixpkgs_git_repository` is a special case of this that only
    supports GitHub source archives.)
  * (low-priority) Inline Nix expression, to support the `nix_file_content`
    use-case.
  * (to-consider) Nix channel, e.g. `nixos-22.11`, with recommended pinning.
  * (to-consider) Git archive, similar to Bazel's own `git_repository`.\
    (Git archive imports tend to be costly, a Nix expression that fetches from
    Git may be the better choice.)
* Expose by
  * Name to other module extensions, such as a Nix package tag, e.g. `name =
    "nixpkgs-stable"`.\
    (To avoid collisions these may have to be scoped on the module level.)
  * [`NIX_PATH` entry][nix-path] to Nix expressions to support angle-bracket
    references, e.g. `import <nixpkgs>`.
  * (to-consider) Define alias tags that map a repository to another `NIX_PATH`
    entry.
  * (to-consider) Default, e.g. `rules_nixkgs_core` or root could define a
    default `nixpkgs`.

### Nix Packages

Support the build, or fetch, and import of Nix deriviations, or store paths,
into a Bazel project.

* Define by
  * Nix attribute path, e.g. `pkgs.hello`, into a Nix repository, e.g.
    `<nixpkgs>`.
  * Nix file, as the top-level Nix expression or an attribute path into it,
    support optional file dependencies.
  * Inline Nix expression, as the top-level Nix expression or an attribute path
    into it.
* Depend on
  * Nix repositories by name, e.g. `"nixpkgs-stable"`.
  * Nix repositories mapped to `NIX_PATH` entry, e.g. `<nixpkgs>`.\
    (A repository alias tag may be sufficient instead of a dedicated package
    attribute.)
  * A default Nix repository, e.g. `<nixpkgs>`.
* Import by
  * Default `BUILD` file
  * Custom `BUILD` file as inline string or in source file.
* Expose by
  * Predictable name or label to targets in the module.\
    (To avoid collisions names may need to be module scoped. A generated
    mapping repository could expose a function to turn names into labels.)
  * Predictable name or label to repository rules, e.g. Gazelle bootstrap Go
    toolchain.

### Nix Provided Toolchains

Support the use of Nix built packages as Bazel toolchains.

* Define by
  * Same as Nix Packages.\
    (Currently toolchains are imported as a special `nixpkgs_package`. These
    implementations should be adapted to support user-defined attribute paths
    and Nix files or inline expressions. Where necessary, needed Nix helpers
    could be exposed in `NIX_PATH` entries of the form `<rules_nixpkgs_LANG>`.)
  * A consistent interface across toolchains.\
    (Currently rules\_nixpkgs toolchains do not all support the same basic
    parameters and patterns. The API should be consistent across languages,
    modulo language imposed requirements or differences.)
  * Specific host and target system or collection thereof.\
    (Currently most toolchains are imported for the host platform. This should
    be generalized to support multiple execute and target platforms.)
* Depend on
  * Same as Nix Packages.
* Import by
  * Dedicated `BUILD` file template.
  * (to-consider) User extensible `BUILD` file template.\
    (The preferable way is to define a `current_toolchain` rule and expose what
    a user may need through providers.)
* Expose by
  * Automatically registered toolchain.\
    (Asking users to apply `use_repo` would expose them to potentially hard to
    predict external repository names and transitive dependencies. Prefer the
    pattern used by rules\_go to generate a collection module hosting all
    toolchains and register all of them in the rules\_nixpkgs\_LANG module.)
  * (to-consider) Starlark constant for use by repository rules.\
    (For example the Python toolchain currently defines a Starlark constant
    holding the label of the Python interpreter for use by repository rules
    like `pip_parse`.)

[bzlmod]: https://bazel.build/external/overview#bzlmod
[module-extension]: https://bazel.build/external/extension
[repository-rule]: https://bazel.build/extending/repo
[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-path]: https://nixos.org/manual/nix/stable/language/values.html#type-path
