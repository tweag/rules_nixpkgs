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

Before Bzlmod, rules\_nixpkgs defined Bazel [repository rules][repository-rule]
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
  * Local file, e.g. `nixpkgs.nix`, with optional file dependencies.\
    Migration target for `nixpkgs_local_repository` with `nix_file`.
  * Inline Nix expression.\
    Migration target for `nixpkgs_local_repository` with `nix_file_content`.
  * HTTP URL, e.g. GitHub source archive.\
    Generalization of `nixpkgs_git_repository`.
  * Github archive.\
    Convenience wrapper around HTTP URL.\
    Migration target for `nixpkgs_git_repository`.
  * (to-consider) Nix channel, e.g. `nixos-22.11`, with recommended pinning.
  * (to-consider) Git archive, similar to Bazel's own `git_repository`.\
    (Git archive imports tend to be costly, a Nix expression that fetches from
    Git may be the better choice.)
* Expose by
  * Name to other module extensions, e.g. Nix package.\
    E.g. `name = "nixpkgs-stable"`.\
  * [`NIX_PATH` entry][nix-path] to Nix expressions.\
    For angle-bracket reference in Nix expression, e.g. `import <nixpkgs>`.
    E.g. `repositories = {"nixpkgs": ...}`.
  * (to-consider) Alias tag to map repository to another `NIX_PATH` entry.
  * (to-consider) Set default repository.\
    Allowed in root or `rules_nixpkgs_core`.

### Nix Packages

Support the build, or fetch, and import of Nix deriviations, or store paths,
into a Bazel project.

* Define by
  * Nix attribute path, e.g. `pkgs.hello`.\
    Migration target for `nixpkgs_package` with `attribute_path`.
    * Defaults to name of tag.\
      Migration target for `nixpkgs_package` without `attribute_path`.
  * Inline Nix expression that provides the attribute.\
    Migration target for `nix_file_content`.
    * Defaults to `import <nixpkgs> { config = {}; overlays = []; }`.
      Migration target for no `nix_file_content` or `nix_file`.
  * Local file that provides the attribute, with optional file dependencies.\
    Migration target for `nix_file`.
  * Optional Nix command-line options.\
    Migration target for `nixopts`.
* Depend on
  * A nixpkgs repository.\
    Migration target for `repository = ...`.
  * Nix repositories mapped to `NIX_PATH` entry.\
    Migration target for `repositories = {...}`.
* Import by
  * Default `BUILD` file
  * Custom `BUILD` file as inline string or in source file.
* Expose by
  * Predictable name or label to targets in the module.\
    (To avoid collisions names may need to be module scoped. A generated
    mapping repository could expose a function to turn names into labels.)
  * Predictable name or label to repository rules, e.g. Gazelle bootstrap Go
    toolchain.
* TODO
  * The `quiet` attribute, should it become a global setting?
  * The `fail_not_supported` attribute, should it become a global setting?
  * The `nix-build` binary, should it be defined by a global setting?
  * Explicit exec- and target-system configuration.\
    * To support cross-compilation projects or cross-platform remote execution.
  * Multi-system configuration.\
    * To support cross-platform projects.

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
* TODO
  * Expose for use-cases like `pip_parse`.

## Constraints

### Module Extensions Don't Compose

* Constraints
  * Bazel module extensions cannot invoke other module extensions, a constraint
    that they share with repository rules or regular rules.
  * Bazel module extensions cannot define or read the tags of other module
    extensions.
* Impact
  * Toolchain tags cannot invoke package tags to generate a dedicated Nix
    package import. And the package tag cannot discover toolchain tags to
    generate corresponding package imports. Instead, any re-use of the package
    import functionality has to occur on the repository rule level.
  * Package or toolchain tags cannot access repository tags directly. Package
    tags could if they were part of the same module extension, but toolchain
    tags certainly can't because their module extension is defined in a
    separate Bazel module as laid out above on module separation. Instead,
    repositories will need to be exposed through an intermediary and imported
    into the package and toolchain repositories through that intermediary.
    A known repository that provides a macro to convert tag names into resolved
    labels to the repository could be such an intermediary, i.e. a hub
    repository, see below.

### Module Extensions Have Global Scope

* Constraint
  * Module extensions are evaluated globally and are given the transitive
    module graph and all tags requested by each module of the current module
    extension.
  * Repository rules are assigned names in a global scope for the current
    module extension.
* Impact
  * Module extensions must either reconcile or avoid name clashes due to
    external workspaces defined based on tags requested by different Bazel
    modules. E.g. if two Bazel modules both request a nixpkgs repository tag
    named `"nixpkgs"`, then the module extension must either unify that tag
    into a single external workspace under that name, or avoid collision by
    generating separate external workspaces with unique names.

### External Workspaces Have Restricted Visibility

* Constraint
  * External workspaces generated by repository rules have to be explicitly
    imported by name into any using Bazel module using a `use_repo` stanza.
  * Only external workspaces generated by a given module extension have
    automatic visibility on other external workspaces generated by the same
    module extension.
  * Module extensions themselves are evaluated in the context of the Bazel
    module that defines them, meaning they cannot directly access the external
    workspaces they generated without an explicit `use_repo` stanza.
  * Visibility is taken into account at label resolution time, i.e. when a
    string is converted into a `Label`.
  * The scope used on label resolution is the surrounding scope of where the
    `Label` constructor is spelled out. In particular, a `Label` invocation
    defined within a closure captures the scope where that closure is defined.
    It will still use that captured scope when invoked in a different scope.
    For example, [rules\_go uses this][rules_go-label-closure] to define a hub
    repository that can expose third-party Go modules. A similar use-case [is
    proposed for an `http` module extension][http-hub-repo-proposal] that
    replaces `http_archive.`
* Impact
  * Imported Nix repositories or packages cannot automatically be referenced
    directly. Instead, they would need to be imported explicitly by the
    requesting module using `use_repo`. However, considering the global scope
    and name collision issue, that would require users to predict the mangled
    names of generated external repositories.
  * Nix package and toolchain module extensions cannot directly reference
    imported Nix repositories, because they are evaluated outside of the scope
    of the Nix repositories module extension. Instead, users could import the
    repository with `use_repo` and forward the resolved label to the package
    and toolchain tags. But, that would require users to predict the mangled
    names of generated external repositories again.
  * A hub repository generated by the repositories module extension could
    expose the resolved labels of imported Nix repositories in a Starlark
    module, similar to the hub repository [used by
    rules\_go][rules_go-label-closure] or [proposed for
    http][http-hub-repo-proposal]. Refer to the initial concept of a
    [hub-and-spokes module][hub-and-spokes] or [hub repository][hub-repo] for
    further details.

### Module Scope Repositories May be Added to Bazel

* Constraint
  * A future follow-up of the [Automatic `use_repo` fixups for module
    extensions][auto-use-repo] proposal was discussed that could introduce
    external workspaces generated by module extensions that are scoped to
    specific Bazel modules. The constraint is that repository mappings need to
    be calculable without loading the module extension, meaning they must be
    fully defined in the `MODULE.bazel` files.
* Impact
  * Repositories generated by the rules\_nixpkgs module extensions that are
    globally unified, thereby potentially used by multiple Bazel modules,
    should have a name that is not prefixed by any Bazel module name, i.e. not
    scoped to any particular Bazel module. In the simplest case this can just
    be the tag name. In light of the above proposal, these could be directly
    imported via `use_repo`.
  * Repositories generated by the rules\_nixpkgs module extensions that are
    specific to the request Bazel module, i.e. only used by that module, should
    be scoped to that particular module, e.g. by using a name that is prefixed
    by that Bazel module's name and version. In future, this could be replaced
    by the `use_local_repo` mechanism.
  * Nix repositories could be passed to Nix package tags as labels imported via
    `use_repo` or `use_local_repo` as described above. Contents of Nix packages
    could be referenced by label directly in the same manner.

[auto-use-repo]: https://docs.google.com/document/d/1dj8SN5L6nwhNOufNqjBhYkk5f-BJI_FPYWKxlB3GAmA/edit?disco=AAAArdGBwhc

### Nixpkgs Repositories or Packages Have No Convenient Canonical Name

* Constraint
  * Nixpkgs repositories may be defined by user provided source files,
    additional configuration arguments, nixpkgs overlays, etc. Outside of the
    most simple use-cases, like referring to the latest release on the
    `nixos-22.11` channel, there is no canonical name that can be assigned to a
    nixpkgs repository that a user could be reasonably expected to predict and
    manually spell out in `use_repo` stanzas or attributes.
  * Nix packages may be definied by a specific nixpkgs repository they are
    based on, as well as user provided sources, additional arguments, and an
    attribute path. Outside of the most simple use-cases, like `pkgs.hello` to
    accept `hello` from an arbitrary nixpkgs repository, there is no canonical
    name that can be assigned to a nixkgs repositor that a user could be
    reasonably expected to predict and manually spell out in `use_repo` stanzas
    or attributes.
* Impact
  * rules\_nixpkgs module extensions will generally not be able to reconcile
    nixpkgs repositories or Nix packages requested across different Bazel
    modules. E.g. if one module requests `nixpkgs` from a local `nixpkgs.nix`
    file and another requests `nixpkgs` from
    `github:NixOS/nixpkgs/nixos-22.05`, then the module extension cannot assume
    that these are interchangeable and cannot unify the two requests. Instead,
    rules\_nixpkgs module extensions will have to import the requested
    repositories and packages as defined in each Bazel module, taking into
    account nixpkgs repositories defined within the scope of that module, or
    explicitly imported from another module (if that's feasible).

### The Diamond Dependency Problem

* Constraint
  * Nix packages imported into Bazel using rules\_nixpkgs can participate in
    diamond shaped dependency graphs. Consider Bazel modules A and B that both
    expose a `cc_library` target, each of which depends on a rules\_nixpkgs
    provided library, say `libz`. Further, assume that the root module combines
    both these `cc_library` targets into a `cc_binary` target. If module A and
    B each import a different instance of `libz` from a different `nixpkgs`
    repository version, then the `cc_binary` target will transitively depend on
    two different versions of `libz` at the same time. If the different
    versions incur API or ABI incompatibilities, then this can cause build or
    runtime errors.
  * Implicit dependencies incurred through the selected toolchain can trigger
    the same kind of problem. For example, an implicit `libc` dependency due to
    a C/C++ compiler toolchain.
  * This is mostly a problem with library type targets instead of binaries
    imported as build tools. However, it could also be an issue with build
    tools. E.g. a code-generator that changed the generated API between
    versions.
  * Monorepo projects often enforce a single version policy to avoid the
    diamond dependency problem.
  * In Nix this problem is usually addressed by providing the ability to
    specify or override inputs to transitive dependencies.
* Impact
  * rules\_nixpkgs module extensions should support a single version policy
    usage pattern. Bazel modules should be able to express that they depend on
    a globally unified version of a Nix repository and Nix package.
  * rules\_nixpkgs itself or the root module should be able to set the global
    defaults.
  * rules\_nixkgs module extensions should support targeted overrides of Nix
    repositories and packages in transitive module dependencies.
    Note, Bazel itself supports this via module overrides from the root module.
    Implementation of this feature is deferred until the need arises. If
    Bazel's builtin mechanism is sufficient, then this feature will not be
    implemented.

### Module Extensions Themselves Don't Generate Output

* Constraint
  * Module extensions can generate files during the execution of their
    implementation function using [`module_ctx.file`]. However, these outputs
    are not written to a cached or persisted location and are not assigned
    Bazel labels. They are only meant as inputs to any tools that the module
    extension may need to invoke, for example a dependency resolver like
    Coursier.
* Impact
  * Module extensions can forward information to the repository rules that they
    invoke directly through attributes. However, any information that they need
    to forward to anywhere external has to be passed through a repository rule
    and written to a public location like a Starlark constant or a Bazel rule
    by that repository rule.

### Module Extensions Are Identified by Their Import Name

* Constraint
  * Bzlmod module extensions are identified by Starlark module and name they
    are imported from - not by reference equality on the underlying extension
    object, [see relevant issue][bzlmod-extension-identifier].
  * Use of the same extension under different identities will cause it to be
    evaluated multiple times with separate namespaces, see [relevant
    issue][bzlmod-undetected-cycles].
* Impact
  * Module extensions cannot be safely re-exported and used from two different
    locations. Extension authors must ensure that all usages import the
    extension from the same `.bzl` module.

### Module Extensions Can Depend on Generated Starlark

* Feature
  * The implementation of a module extension is defined in a Starlark function.
    The corresponding `.bzl` file can `load` another `.bzl` file that was
    generated by a repository rule that was in turn invoked by a module
    extension.\
    This is [intended behavior and a supported use-case][bzlmod-import].
* Impact
  * The module extension for defining nixkgs repositories could invoke a
    repository rule that generates a Starlark file that contains the required
    metadata to expose the repositories to other rules\_nixpkgs module
    extensions, e.g. to the module extension for Nix packages. This needs to
    take the restrictured visibility mentioned above into account and define a
    hub repository.

## Example Usage

### Global Default Repository

rules\_nixpkgs\_core itself will define a global default `nixpkgs` repository,
any module can reference this global default repository like so.

```python
use_extension("//extensions:repository.bzl", "nix_repo")

nix_repo.default(name = "nixpkgs")
```

### Local Repository

Any Bazel module can define custom Nix repositories for local use.

```python
nix_repo.github(
    name = "nixpkgs-unstable",
    commit = "1eeea1f1922fb79a36008ba744310ccbf96130e2",
    sha256 = "d6759a60a91dfd03bdd4bf9c834e1acd348cf5ca80c6a6795af5838165bc7ea6",
)
```

### Repository Override

The root module can override the default set by rules\_nixpkgs\_core.

```python
nix_repo.override(name = "nixpkgs")
nix_repo.http(
    name = "nixpkgs",
    url = "https://github.com/NixOS/nixpkgs/archive/1eeea1f1922fb79a36008ba744310ccbf96130e2.tar.gz",
    sha256 = "d6759a60a91dfd03bdd4bf9c834e1acd348cf5ca80c6a6795af5838165bc7ea6",
    strip_prefix = "nixpkgs-1eeea1f1922fb79a36008ba744310ccbf96130e2",
)
```

rules\_nixpkgs\_core uses the same mechanism to define the global default.

```
nix_repo.override(name = "nixpkgs")
nix_repo.github(
    name = "nixpkgs",
    tag = "22.11",
    sha256 = "ddc3428d9e1a381b7476750ac4dbea7a42885cbbe6e1af44b21d6447c9609a6f",
)
```

### Unified Nix Package

Bazel modules can depend on Nix packages by attribute path into a global Nix
repository (by default `nixpkgs`). These package references are unified
globally based on the attribute path, such that every Bazel module requesting
this package will be given the same instance of the package. This is meant to
avoid diamond dependency issues, see above.

```python
use_extension("@rules_nixpkgs_core//extensions:package.bzl", "nix_pkg")

nix_pkg.attr(attr = "jq")
nix_pkg.attr(attr = "gawk")
```

### Local Nix Package

A Bazel module can import a custom Nix package from an expression or file and
provide a custom BUILD file template if required. The possibilities for
customization are too great to attempt global unification of such packages. If
two different Bazel modules effectively request the same such Nix package, then
rules\_nixkgs will still generate two separate external repositories to import
the package for each module.

```python
nix_pkgs.local_attr(name = "jq", repo = "nixpkgs-unstable")

nix_pkg.local_expr(
    name = "awk",
    expr = """\
with import <nixpkgs> { config = {}; overlays = []; };
gawk-with-extensions.override {
    extensions = with gawkextlib; [ csv json ];
}
    """,
    repo = "nixpkgs-unstable",
)
```

## Interface

### Nix Repositories

The `rules_nixpkgs_core` module exposes the module extension `nix_repo` which
offers tags to define Nix repositories:

* `default(name)`\
  * `name`: `String`; Use this global default repository.
* `github(name, org, repo, tag, commit)`\
  * `name`: `String`; unique name.
  * `org`: optional, `String`; The GitHub organization hosting the repository.\
    Default: `NixOS`.
  * `repo`: optional, `String`; The name of the GitHub repository.\
    Default: `nixpkgs`.
  * `tag`: optional, `String`; The Git tag to download.\
    Specify one of `tag` or `commit`.
  * `commit`: optional, `String`; The Git commit to download.\
    Specify one of `tag` or `commit`.
  * `sha256`: optional, `String`; The SHA-256 hash of the downloaded archive.
  * `integrity`: optional, `String`; Expected checksum of the archive, in
    Subresource Integrity format.
* `http(name, url, urls, sha256, integrity, strip_prefix)`\
  * `name`: `String`; unique name.
  * `url`: optional, `String`; URL to download from.\
    Specify one of `url` or `urls`.
  * `urls`: optional, `String`; List of URLs to download from.\
    Specify one of `url` or `urls`.
  * `sha256`: optional, `String`; The SHA-256 hash of the downloaded archive.
  * `integrity`: optional, `String`; Expected checksum of the archive, in
    Subresource Integrity format.
  * `strip_prefix`: optional, `String`; A directory prefix to strip from the extracted files.
* `file(name, file, file_deps)`\
  * `name`: `String`; unique name.
  * `file`: `Label`; the file containing the Nix expression.
  * `file_deps`: optional, List of `Label`, files required by `file`.
* `expr(name, expression)`\
  * `name`: `String`; unique name.
  * `expression`: `String`; the Nix expression.
* `override(repo)` (only allowed in rules\_nixpkgs\_core and root)\
  * `repo`: `String`; The name of the repository to override.

All `name` attributes define a unique name for the given Nix repository within
the scope of the requesting module.

The extension is defined in its own Starlark module under
`@rules_nixpkgs_core//extensions:repository.bzl`.

The extension generates a hub repository called `nixpkgs_repositories` that
exposes a macro from `//:defs.bzl` to access the imported repositories from the
scope of the calling module:

* `nix_repo(module, name)`\
  Attrs:
  * `module`: `String`; name of the calling Bazel module.\
    Needed until Bazel offers an API to infer the calling module.
    See, [#17652][bazel-17652].\
    Note, this is ambiguous for multi-version overrides.\
    TODO: Handle multi-version overrides.
  * `name`: `String`; name of the repository.\
    This is the name used on the `nix_repo` tag.

  Returns:\
    The resolved `Label` object to the repository.

Users are not expected to invoke `nix_repo` directly. Instead, it will be
invoked by the package and toolchain module extensions to access the relevant
repositories.

### Nix Packages

The `rules_nixpkgs_core` module exposes the module extension `nix_pkg` which
offers tags to define Nix packages:

* `attr(attr)` (globally unified)\
  * `attr`: `String`; the attribute path.\
* `local_attr(name, attr, repo, build_file, build_file_content)`\
  * `name`: `String`; unique name.
  * `attr`: optional, `String`; the attribute path.\
    Default: `name`.
  * `repo`: optional, `String`; the `nixpkgs` repository to import from.\
    Default: `nixpkgs`.
  * `build_file`: optional, `Label`; `BUILD` file to write into the external
    workspace.\
    Specify at most one of `build_file` or `build_file_content`.
  * `build_file_content`: optional, `Label`; `BUILD` file content to write into
    the external workspace.\
    Specify at most one of `build_file` or `build_file_content`.
* `local_file(name, attr, file, file_deps, repo, repos)`\
  * `name`: `String`; unique name.
  * `attr`: optional, `String`; the attribute path.\
    Default: `name`.
  * `file`: `Label`; the file containing the Nix expression.
  * `file_deps`: optional, List of `Label`, files required by `file`.
  * `repo`: optional, `String`; use this `nixpkgs` repository.
    Equivalent to `repos = {"nixpkgs": repo}`.
    Specify only one of `repo` or `repos`.
    Default: `nixpkgs`.
  * `repos`: optional, Dict of `String`; use these Nix repositories.
    The dictionary key represents the name of the `NIX_PATH` entry.
    Specify only one of `repo` or `repos`.
  * `build_file`: optional, `Label`; `BUILD` file to write into the external
    workspace.\
    Specify at most one of `build_file` or `build_file_content`.
  * `build_file_content`: optional, `Label`; `BUILD` file content to write into
    the external workspace.\
* `local_expr(name, attr, expr, repo, repos)`\
  * `name`: `String`; unique name.
  * `attr`: optional, `String`; the attribute path.\
    Default: `name`.
  * `expr`: `String`; the Nix expression.
  * `repo`: optional, `String`; use this `nixpkgs` repository.
    Equivalent to `repos = {"nixpkgs": repo}`.
    Specify only one of `repo` or `repos`.
    Default: `nixpkgs`.
  * `repos`: optional, Dict of `String`; use these Nix repositories.
    The dictionary key represents the name of the `NIX_PATH` entry.
    Specify only one of `repo` or `repos`.
  * `build_file`: optional, `Label`; `BUILD` file to write into the external
    workspace.\
    Specify at most one of `build_file` or `build_file_content`.
  * `build_file_content`: optional, `Label`; `BUILD` file content to write into
    the external workspace.\

All `name` attributes define a unique name for the given Nix repository within
the scope of the requesting module.

The extension is defined in its own Starlark module under
`@rules_nixpkgs_core//extensions:package.bzl`.

The extension generates a hub repository called `nixpkgs_packages` that exposes
a macro from `//:defs.bzl` to access the imported packages from the scope of
the calling module:

* `nix_pkg(module, name, label)`\
  Attrs:
  * `module`: `String`; name of the calling Bazel module.\
    Needed until Bazel offers an API to infer the calling module.
    See, [#17652][bazel-17652].\
    Note, this is ambiguous for multi-version overrides.\
    TODO: Handle multi-version overrides.
  * `name`: `String`; name of the package.\
    This is the name used on the `nix_pkg` tag.
  * `label`: `String`; the label to resolve within the package.

  Returns:\
  The resolved `Label` object.

### Nix Toolchains

The `rules_nixpkgs_LANG` modules expose module extensions
`nixpkgs_LANG_toolchain` which offer tags to define toolchains provided by Nix.

TODO: Define the common API for the toolchains. Individual toolchains may
deviate due to language specific constraints or features.

The extension generates a hub repository called `nixpkgs_LANG_toolchains` that
contains toolchain targets for all imported toolchains. The
`rules_nixpkgs_LANG` module registers the toolchains
`@nixpkgs_LANG_toolchains//:all`.

[bzlmod]: https://bazel.build/external/overview#bzlmod
[module-extension]: https://bazel.build/external/extension
[repository-rule]: https://bazel.build/extending/repo
[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-path]: https://nixos.org/manual/nix/stable/language/values.html#type-path
[rules_go-label-closure]: https://github.com/bazelbuild/bazel-gazelle/pull/1423/commits/e24594cb22b011d85ea8c3b61f677e49d553da10#diff-7f2bd6c16dfad35f69dccdb3ed29da981c1c4bf3cf709ceead4816e2c6829cdcR21
[http-hub-repo-proposal]: https://github.com/bazelbuild/bazel/issues/17141#issuecomment-1402446226
[hub-and-spoke]: https://github.com/bazelbuild/bazel/issues/17493
[hub-repo]: https://github.com/bazelbuild/bazel/issues/17048
[bzlmod-extension-identifier]: https://github.com/bazelbuild/bazel/issues/17564#issuecomment-1448442715
[bzlmod-undetected-cycles]: https://github.com/bazelbuild/bazel/issues/17564
[bzlmod-import]: https://bazelbuild.slack.com/archives/C014RARENH0/p1677600643532639?thread_ts=1677077009.456189&cid=C014RARENH0
[bazel-17652]: https://github.com/bazelbuild/bazel/issues/17652
