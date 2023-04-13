# A guide to rules_nixpkgs

In order to explain the benefits of rules\_nixpkgs in practical Bazel
deployments, let's review some properties Bazel emphasises that distinguish it
from various other build systems. Bazel is a modern build system that its users
value for the ability to define and run builds that are both _fast_ and
_correct_:

- builds are fast, thanks to advanced caching and distributed builds.
- builds are correct, in that build artifacts always reflect the state of their
  declared inputs, so the user never needs to run `bazel clean`

Bazel's caching and distributed build features depend on build definitions being
_correct_ by capturing all required dependencies. Build actions are run in
isolation, which helps to ensure that build definitions are indeed correct in
this manner. This is referred to as _hermeticity_: a build is hermetic if there
are no external influences on it. However, Bazel is only hermetic if certain
conditions are met, and they aren't in many people's build setups. In practice,
Bazel build products fail to be reproducible by default, because Bazel silently
depends on various things present in the global environment, like a C++
compiler. 

Another related issue is that external dependencies must be Bazel-ified in order
to be usable from within Bazel. For language ecosystems where there is
widespread adoption of a package manager, and a Bazel ruleset that allows those
packages to be accessed from Bazel, this isn't much of an issue. For instance,
Python dependencies are taken care of by `rules_python`. However, in the case of
C/C++ project, or with library headers, third-party dependencies can still be
difficult to manage.

The rules_nixpkgs ruleset enables the use of the extensive
[Nixpkgs](https://github.com/NixOS/nixpkgs) package set from Bazel, allowing it
to provision external dependencies via the
[Nix](https://nixos.org/download.html) package manager. Nix provides strong
hermeticity and reproducibility guarantees for all build products, which are
defined in a language also called Nix. A sizeable collection of such package
definitions is available in the Nixpkgs repository, which can then be used
freely from Bazel.

### Supported systems

This guide only targets Linux at present. Most of it should work in a macOS environment (tracked at [#371](https://github.com/tweag/rules_nixpkgs/issues/371)): please open an issue if something doesn't work!

## A basic Bazel project

Let's start with a simple example, on the Bazel "happy path": building a simple
C/C++ project. The project structure we'll work with is available
[here][template] if you'd prefer to not go through the steps yourself.

We start with an ordinary Bazel workspace setup:

```
- src
  - BUILD
  - hello-world.cc
- WORKSPACE
```

where WORKSPACE is empty, and BUILD contains a single `cc_binary` rule:

```bzl
cc_binary(
    name = "hello-world",
    srcs = ["hello-world.cc"],
)
```

`src/hello-world.cc` is simply:

```cpp
#include <iostream>

int main(int argc, char** argv) {
  std::cout << "Hello world!" << std::endl;
  return 0;
}
```

Verify that this builds:

```
> bazel run //src:hello-world
INFO: Analyzed target //src:hello-world (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //src:hello-world up-to-date:
  bazel-bin/src/hello-world
INFO: Elapsed time: 0.063s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
Hello world!
```

## The lack of hermeticity

Bazel is prized for its hermetic and reproducible builds, but this example
already demonstrates that isn't a completely accurate description: we haven't
told Bazel what C++ compiler to use, or where to find the compiler and the
auxiliary tools it relies on to assemble and link code. It simply looks for
appropriately-named executables in the PATH and sets up a C/C++ compiler
toolchain in `@local_config_cc` that "should work". 

This is problematic, and not just because of pedantic concerns regarding the
precise meaning of "hermeticity". We have no control over what compiler is used:
build products can vary greatly between two versions of the same compiler, let
alone between different compilers. Bazel, by default, chooses GCC on a Linux
machine and Clang/LLVM on a macOS machine, which can mean that the same bit of
hot code, say, vectorizes correctly on one platform but not on the other due to
some difference between the two compilers, resulting in wildly different
performance characteristics. System library versions are also not controlled, so
build products will depend on whatever versions of those happen to be available
on the host during the build, which may very well change after a simple system
package upgrade.

## Solutions to the issue

There are two common ways that Bazel users work around these issues and achieve
partial or full hermeticity. 

The first is to give up trying to make Bazel not depend on the global
environment, and instead to control that global environment ourselves so that
the implicit dependencies end up being the same every time. To do so, we run all
builds in sandboxes or VMs that all share the exact same configuration.

The most common variation of this approach uses Docker containers, and comes
with certain disadvantages. We don't know exactly what components of the Docker
image our build products depend on, so any change to the container invalidates
everything that was built using it, and we need to rebuild our project from
scratch, losing incrementality. In addition, the most common ways to build
Docker images involve non-reproducible actions like executing `apt update` or
similar. This means that what should be a version bump to a single library can
pull in changes to the versions of other dependencies. Docker images are usually
cached for efficiency, which means now large binary blobs have to be moved from
machine to machine and updated correctly as an essential part of CI and release
processes.

The other solution is to eliminate the dependency on the global environment from
within Bazel by defining your own compiler toolchain. This is done by telling
Bazel it can find the executable binaries it wants (`cc`, `ld`, `as`, ...) at
some path where we manually maintain them. These have to be provisioned and
versioned manually, often by checking them out directly into the source tree.
Bazel can then be instructed to use this new toolchain instead of the default
`@local_config_cc`. In this case, as with the Docker solution, the build depends
on non-code elements for which versioning and maintenance is more complex than
for ordinary code. From a security point of view, this also expands the "trusted
base", and verifying the provenance of these binary blobs now becomes an
additional responsibility.

rules\_nixpkgs offers a third approach, by allowing a build to depend on system
dependencies and toolchains in a _fine-grained_ and _declarative_ manner:

- _fine-grained_, since we specify exactly which packages and libraries we
  depend on
- _declarative_, since we only specify _what_ libraries we need, instead of
  writing code to install and upgrade them

This has several advantages:
- Rebuilds are minimised: the addition of a new library dependency via
  rules_nixpkgs will not invalidate unrelated targets that were built before it
  was added.
- System images and installation scripts no longer have to be carefully managed:
  the work of turning our declarative description into a correct build
  environment with all our dependencies is handled by Nix.
- Virtualization or containers are no longer needed: Nix provides the
  reproducibility and predictability benefits one gets from running all builds
  in identical environments.

## Transitioning the build to using Nix

We start by installing Nix as per the official
[instructions](https://nixos.org/download.html). Any recent version should be
fine. For reference, this guide was tested using:

```
> nix --version
nix (Nix) 2.13.2
```

Getting everything working requires some boilerplate, which we'll go through
right now in detail, and then set up our project to perform builds using
rules\_nixpkgs to source dependencies. A high-level overview of what we'll do:
- create a flake.nix file, in which we define a development shell with the
  dependencies used during development
- enter the shell for the first time, which will provide a pinned Nixpkgs
  version in a flake.lock file that we can then use consistently within our
  build as well as a source of dependencies during the build
- adapt the `WORKSPACE` file to use rules_nixpkgs, with the Nixpkgs version
  pinned above
- define a hermetic Nixpkgs-provided CC toolchain
- tell Bazel to use it by default
- test that everything works

## Nix development shells

Nix has quite a few features that come in handy when working on a software
project with a team, one of which is the ability to define hermetic shell
environments. Conceptually, these are similar to Python virtualenvs, except with
unified support for both system libraries and language-specific dependencies
across many different languages, guaranteeing consistent versions of these for
different users across different platforms. Even better, it's possible to deny
access to anything _not_ defined in the shell, which makes it almost impossible
to write builds that are _incorrect_ and fail to declare all their dependencies.

Nix itself is fairly old (the first commit dates back to 2003) and as old
software tends to do, there are "legacy" and "modern" ways of doing certain
things that are both still in common use. When defining development shells and
setting up projects for use with Nix, we choose the newer "flake" method over
the legacy method (involving a `shell.nix` file) that you may run into in other
places.

A _flake_, defined in a file conventionally called `flake.nix`, can be thought
of as a self-contained "Nix module". For our purposes, it will suffice to think
of it as a way to define a cross-platform development shell, with the versions
of the _inputs_ to the shell pinned in a lockfile (`flake.lock`). To get
started, put the following code in a file named `flake.nix` at the root of the
repository:

```nix
{
  inputs = {
    # Track a specific tag on the nixpkgs repo.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    # The flake format itself is very minimal, so the use of this
    # library is common.
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Here we can define various kinds of "outputs": packages, tests, 
  # and so on, but we will only define a development shell.

  outputs = { nixpkgs, flake-utils, ... }:

    # For every platform that Nix supports, we ...
    flake-utils.lib.eachDefaultSystem (system:

      # ... get the package set for this particular platform ...
      let pkgs = import nixpkgs { inherit system; };
      in 
      {

        # ... and define a development shell for it ...
        devShells.default =

          # ... with no globally-available CC toolchain ...
          pkgs.mkShellNoCC {
            name = "rules_nixpkgs_shell";

            # ... which makes available the following dependencies, 
            # all sourced from the `pkgs` package set:
            packages = with pkgs; [ bazel_5 bazel-buildtools cacert nix git ];
          };
      });
}
```

It's not necessary at this juncture to understand the details of the Nix code
above. (For those curious, [this][flake-post] series of articles on the Tweag
blog is a good start.) It's worth noting the `packages = ...` line near the end:
the square brackets, as you might expect, set off a _list_ in Nix, with elements
separated (admittedly a bit oddly) by whitespace. If you need packages in your
development shell that aren't listed there already (compilers, development
tools, editors, anything at all) you can add them to the `packages` list, and
they'll become available within the shell when you enter it. In order to search
for the package you want in Nixpkgs, there is a [package
search](https://search.nixos.org/packages) function available on the Nixpkgs
website.

We've also done something else slightly out of the ordinary. The usual way to
define a development shell is with the commonly-used `mkShell` Nix function,
which creates a development shell with a given set of available dependencies
_and_ a default CC toolchain. We've replaced it with `mkShellNoCC`, which, as
the name suggests, does the same job but without implicitly making a
Nix-provided CC toolchain available.

To enter the development shell, one can run:
```
$ nix develop
```

When running this for the first time, a `flake.lock` file is initialised,
containing the exact versions of each dependency in `inputs` (which for us is
basically just `nixpkgs`). This can be committed to the repository, and ensures
that when others use the same environment, they will be provided the same
versions of those dependencies, which means that the environment will be
consistent across platforms. We will also use that same `flake.lock` as the
single source of truth for the Nixpkgs version used in our build below.

It's worth explicitly mentioning how useful being able to fix a version of
Nixpkgs is for us: doing this allows us to select a consistent set of package
revisions in one go, instead of having to maintain dependency versions for
individual dependencies. Often one prefers to choose a tag for a stable release,
which are of the form `nixos-yy.mm` where `yy` are the last two digits of a
year, and `mm` is a month. Each stable release tag undergoes stringent
verification via CI that packages in it will function correctly individually and
play well together.

### Upgrading the Nixpkgs version used (and other flake inputs)

As with all dependencies, it's good to upgrade the version of the `nixpkgs`
input from time to time, which will bump the versions of all Nix-provided
dependencies. In the example above, the `nixpkgs` dependency is set to follow
the `nixos-22.05` tag, and we can pull the latest commit from that branch using:

```
$ nix flake lock --update-input nixpkgs
```

It is also possible to change the Nixpkgs dependency to any branch: for
instance, we could switch to `master` and receive bleeding-edge dependencies, or
(more practically) we could choose to follow a newer tag (22.11 is available
right now) by making the following change in `flake.nix`:

```diff
-    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
+    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
```

To update _all_ dependencies, one uses:

```
$ nix flake update
```

In the current example, this is effectively equivalent, since the only
dependency we have apart from Nixpkgs itself is `flake-utils`, which is a small
library of simple utilities that aren't changed much.  However, if you integrate
more Nix-based dependencies or utilities into your shell, this will take care of
all of them in one go, and update the `flake.lock` to include all of the
changes.

## Using `direnv` with Nix

The use of this feature can be made even more seamless by using
[direnv](direnv), which has support for the `flake.nix` file we used to describe
the development shell.

Put the following in a file called `.envrc` at the root of the repo:

```sh
# First, we import the nix-direnv library.
# This is required for versions of direnv older than 2.29.0, since they do not 
# support `use flake`, and recommended in all cases, since it caches the 
# environment and prevents dependencies from being garbage-collected by Nix.

if ! has nix_direnv_version || ! nix_direnv_version 2.2.1; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.2.1/direnvrc" "sha256-zelF0vLbEl5uaqrfIzbgNzJWGmLzCmYAkInj/LNxvKs="
fi

# Load the development shell defined in the flake.nix file
use flake
```

direnv will ask you to manually allow running the code in the file:

```
direnv: error /home/w/sb/rules_nixpkgs_cc_template/.envrc is blocked. Run `direnv allow` to approve its content
$ direnv allow
direnv: loading ~/sb/rules_nixpkgs_cc_template/.envrc
direnv: using flake
...
``` 

Now whenever this directory is entered in the shell, this environment will be
activated automatically.

## Exposing the locked version of Nixpkgs to the Bazel build

In order to ensure that our development shell uses the same Nixpkgs version as
what rules\_nixpkgs uses below for our Bazel builds, we write a small shim that
reads the data from the `flake.lock` and provides that version of Nix.

Put the following in `nixpkgs.nix`, at the root of the repository:

```nix
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  spec = lock.nodes.nixpkgs.locked;
  nixpkgs = fetchTarball "https://github.com/${spec.owner}/${spec.repo}/archive/${spec.rev}.tar.gz";
in
import nixpkgs
```

As is hopefully visible from reading the code, this reads the contents of
`flake.lock` (which is plain JSON) and uses that to fetch the right version of
Nixpkgs. We can access this from rules\_nixpkgs repository rules below.

## Integrating rules_nixpkgs into the build

Now that all the prerequisites are sorted, we can edit the `WORKSPACE` file to
instruct Bazel to load the `rules_nixpkgs` ruleset and its dependencies:

```bazel
# load the http_archive rule itself
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# load rules_nixpkgs
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-0.9.0",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/refs/tags/v0.9.0.tar.gz"],
    sha256 = "b01f170580f646ee3cde1ea4c117d00e561afaf3c59eda604cf09194a824ff10",
)

# load everything that rules_nixpkgs rules need to work
load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()
```
(The `sha256` attribute is optional, but adding it guarantees the stability of the release tarball.)

Now we can tell rules\_nixpkgs to use our `nixpkgs.nix` above to import this
Nixpkgs collection into Bazel:

```bazel
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_local_repository", "nixpkgs_cc_configure")
nixpkgs_local_repository(
    name = "nixpkgs",
    nix_file = "//:nixpkgs.nix",
    nix_file_deps = ["//:flake.lock"],
)
```

Now this Nixpkgs collection has been imported into Bazel, and can be referenced
as `@nixpkgs`. (Also note the `nix_file_deps` line, which tracks the dependency
of the `nixpkgs.nix` file on the `flake.lock` file from where we read the
Nixpkgs commit hash.)

# A hermetic CC toolchain

We can now define a CC toolchain that will be provisioned by Nix using package
definitions from the 22.05 release of Nixpkgs.

```bazel
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  name = "nixpkgs_config_cc",
)
```

This will select the default `stdenv.cc` package as the compiler, drawing
auxiliary tools from `stdenv.cc.bintools`. However, one can write a little bit
of Nix to configure this:

```bazel
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  nix_file_content = "(import <nixpkgs> {}).gcc11",
  name = "nixpkgs_config_cc",
)
```

`(import <nixpkgs> {})` loads the entire package set into an attribute set
(Nix's equivalent of a record), and `.gcc11` selects the appropriate CC
toolchain from it. It is possible to customize the compiler further using more
Nix if desired: you could, for instance, point Nix to a custom fork of Clang
containing support for a new architecture, and have everything work seamlessly.

With this, we now have a fully hermetic CC toolchain that will behave correctly
across platforms. It remains to tell Bazel to use it by default, instead of
`@local_config_cc`. To do so, we put the following into `.bazelrc` at the root
of the repository:

```
build --host_platform=@io_tweag_rules_nixpkgs//nixpkgs/platforms:host
build --crosstool_top=@nixpkgs_config_cc//:toolchain
```

At a high level, the first directive tells Bazel that we are running on a Nix
machine, for which special configuration is needed that rules_nixpkgs defines
(in a similar way to how Bazel makes adjustments when running on macOS vs
Linux). The second directive tells Bazel to use the toolchain
`@nixpkgs_config_cc//:toolchain` (which requires Nix support) by default for all
C++ compilation.

Now `bazel build` and `bazel run` should use this toolchain by default for C/C++
compilation. This can be verified using Bazel's `--toolchain_resolution_debug`
switch:

```
> bazel build //src:hello-world --toolchain-resolution-debug '.*'
INFO: Build option --toolchain_resolution_debug has changed, discarding analysis cache.
INFO: ToolchainResolution: Target platform @rules_nixpkgs_core//platforms:host: Selected execution platform @rules_nixpkgs_core//platforms:host, 
INFO: ToolchainResolution:     Type @bazel_tools//tools/cpp:toolchain_type: target platform @rules_nixpkgs_core//platforms:host: Rejected toolchain @nixpkgs_config_cc//:cc-compiler-armeabi-v7a; mismatching values: arm, android
INFO: ToolchainResolution:   Type @bazel_tools//tools/cpp:toolchain_type: target platform @rules_nixpkgs_core//platforms:host: execution @io_tweag_rules_nixpkgs//nixpkgs/platforms:host: Selected toolchain @nixpkgs_config_cc//:cc-compiler-k8
INFO: ToolchainResolution:     Type @bazel_tools//tools/cpp:toolchain_type: target platform @rules_nixpkgs_core//platforms:host: Rejected toolchain @local_config_cc//:cc-compiler-armeabi-v7a; mismatching values: arm, android
INFO: ToolchainResolution:     Type @bazel_tools//tools/cpp:toolchain_type: target platform @rules_nixpkgs_core//platforms:host: Rejected toolchain @local_config_cc//:cc-compiler-armeabi-v7a; mismatching values: arm, android
INFO: ToolchainResolution: Target platform @rules_nixpkgs_core//platforms:host: Selected execution platform @rules_nixpkgs_core//platforms:host, type @bazel_tools//tools/cpp:toolchain_type -> toolchain @nixpkgs_config_cc//:cc-compiler-k8
INFO: ToolchainResolution: Target platform @rules_nixpkgs_core//platforms:host: Selected execution platform @rules_nixpkgs_core//platforms:host, 
INFO: ToolchainResolution: Target platform @rules_nixpkgs_core//platforms:host: Selected execution platform @rules_nixpkgs_core//platforms:host, 
INFO: ToolchainResolution: Target platform @rules_nixpkgs_core//platforms:host: Selected execution platform @rules_nixpkgs_core//platforms:host, 
INFO: Analyzed target //src:hello-world (0 packages loaded, 177 targets configured).
INFO: Found 1 target...
Target //src:hello-world up-to-date:
  bazel-bin/src/hello-world
INFO: Elapsed time: 0.155s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
Hello world!
```

The line that says `Selected execution platform
@rules_nixpkgs_core//platforms:host, type @bazel_tools//tools/cpp:toolchain_type
-> toolchain @nixpkgs_config_cc//:cc-compiler-k8` confirms that the
Nixpkgs-provided CC toolchain is indeed being used.

# Making Nix optional

It is entirely possible to make the use of Nix optional in a Bazel setup. To do
so, we use `bazelrc` configs to only enable Nix-specific configuration when a
`--config` flag is provided, like so:

```
build:nix --host_platform=@io_tweag_rules_nixpkgs//nixpkgs/platforms:host
build:nix --crosstool_top=@nixpkgs_config_cc//:toolchain
```

None of these options will apply to `bazel build` or `bazel run` unless an extra
`--config nix` parameter is passed:

```
> bazel run //src:hello-world --config=nix
...
```

However, when doing this, it is necessary that the `WORKSPACE` file define a
non-Nix toolchain (for example, the default bindist) in addition to the
Nix-provided one, and that the Nix-provided one is registered first, before the
non-Nix one. This is because the Nix-provided toolchain is marked with an
execution platform constraint, as noted earlier when we were creating our
`.bazelrc`, which makes it only be selected by Bazel when the `nixpkgs` platform
is available. However, non-Nix toolchains typically do not have such
constraints, so Bazel will unconditionally select them if they appear first in
the file. 

In the CC case, the "default bindist" is built into Bazel, so this doesn't need
to be done explicitly. For non-CC toolchains, this means that the
`rules_nixpkgs`-provided toolchain registration step must come before one
provided by the usual ruleset: for instance, in the [Go case][go-register-toolchains],
`nixpkgs_go_configure()` must come before the call to `go_register_toolchains()`
from `rules_go`.

## Further resources

This guide is intended to be a crash course in the subset of Nix required to
begin using rules_nixpkgs, but it barely scratches the surface of the Nix
project or the broader Nix ecosystem. For those interested in learning more, we
provide some jumping-off points here.

There are various different things that are commonly referred to as Nix — a
programming language used to define packages, a package manager, as well as the
command-line interface that allows the user to evaluate programs written in the
language and interact with the package manager. Guides on each of these topics
are available, for example, at [nix.dev](https://nix.dev). A more extensive set
of links on various Nix and Nix-related topics can be found on the
[awesome-nix](https://github.com/nix-community/awesome-nix) repo.

A step-by-step, hands-on introduction to using Nix+Bazel to build a polyglot
project is available at the [Nix+Bazel
Codelab](https://github.com/tweag/nix_bazel_codelab).

API documentation for rules\_nixpkgs can be found in the
[README](https://github.com/tweag/rules_nixpkgs/blob/master/README.md), with
toolchain-specific API documentation in the README files in the respective
directories under
[`toolchains/`](https://github.com/tweag/rules_nixpkgs/tree/master/toolchains).

[path-link]: https://github.com/bazelbuild/bazel/blob/master/src/main/java/com/google/devtools/build/lib/bazel/rules/BazelRuleClassProvider.java#L563
[direnv]: https://github.com/direnv/direnv
[template]: ../examples/cc-template
[flake-post]: https://www.tweag.io/blog/2020-05-25-flakes/
[go-register-toolchains]: https://github.com/tweag/rules_nixpkgs/blob/56b9cff9d175b916abdb36920a669b1face49e04/examples/toolchains/go/WORKSPACE
