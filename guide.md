# A guide to rules_nixpkgs

TODO: is the flake shell pure? because if this is run on a non-nixos system, and /usr/bin/gcc continues to be visible, that messes things up
TODO: document nixpkgs.nix

---

Bazel is a modern build system valued for _fast_ and _correct_ builds.

- Builds are fast, thanks to advanced caching and distributed builds.
- Builds are correct, in that build artifacts always reflect the state of their
  declared inputs. In other words, the user should never need to run `bazel
  clean`.

Bazel's caching and distributed build features depend on build definitions being
_correct_ by capturing all required dependencies. Build actions are run in
isolation, which helps to ensure that build definitions are indeed correct in
this manner. This is referred to as "hermeticity": A build is hermetic if there
are no external influences on it.  However, Bazel is only hermetic if certain
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

# A basic Bazel project

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

`src/hello-world.cc` is simply

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

# The lack of hermeticity

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
build products will depend on whatever versions of happen to be available on the
host during the build, which may very well change after a simple system package
upgrade.

# How rules_nixpkgs solves the issue

There are two common ways that Bazel users work around these issues and achieve
partial or full hermeticity. 

The first is to give up trying to make Bazel not depend on the global
environment, and instead to control that global environment ourselves so that
the implicit dependencies end up being the same every time. To do so, we run all
builds in sandboxes or VMs that all share the exact same configuration.

The most common variation of this approach uses Docker containers, and comes
with certain disadvantages. We don't know exactly what components of the Docker
image our build products depend on, so any change to the container invalidates
everything that was built using it. In addition, the most common ways to build
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

# Transitioning the build to using Nix

We start by installing Nix as per the official
[instructions](https://nixos.org/download.html).

```
> nix --version
nix (Nix) 2.12.0
```

rules_nixpkgs requires a Nix-provided Bazel version. We can use the `nix-env
-i` command to install Bazel into the user environment, but this pollutes the
shell environment and will prevent the use of the globally installed Bazel (if
any) in other projects. A better solution is to use `nix-shell`, which can
create development environments containing specific dependencies on demand,
somewhat akin to Python virtualenvs but for any kind of dependency. Here's a
demonstration of how it works:

```
> hello
hello: command not found
> nix-shell -p hello
nix-shell> hello
Hello, world!
nix-shell> exit
> hello
hello: command not found
```

For our purposes, we can enter a shell with a Nix-provided Bazel in a similar manner:
```
> nix-shell -p bazel_5
```
(`nix-shell` uses `bash` by default; if you use, say, zsh, use `nix-shell -p bazel_5 --run zsh`.)

Once that's done, we can then edit the `WORKSPACE` file to instruct Bazel to load the `rules_nixpkgs` ruleset:

```bazel
# download the http_archive rule itself
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# download rules_nixpkgs
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-9f08fb2322050991dead17c8d10d453650cf92b7",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/9f08fb2322050991dead17c8d10d453650cf92b7.tar.gz"],
    sha256 = "46aa0ca80b77848492aa1564e9201de9ed79588ca1284f8a4f76deb7a0eeccb9",
)

# load everything that rules_nixpkgs rules need to work
load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()
```

Now we can select a version of the Nixpkgs repository from which all of our
packages will be drawn. Any Git commit hash or tag is allowed. This way, we
select a consistent set of package revisions in one go instead of having to
maintain dependency versions for individual dependencies. Often this will be a
tag for a stable release, which ensures that there has been especially
stringent verification that packages in it will function correctly individually
and play well together. Here we use the 22.05 release:

```bazel
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository")
nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "22.05",
    sha256 = "",
)
```

Specifying the SHA-256 hash here provides a stronger guarantee of
reproducibility: Nix will check that the downloaded Git archive has a hash that
matches the one provided.

# A hermetic CC toolchain

We can now define a CC toolchain that will be provisioned by Nix using
package definitions from the 22.05 release of Nixpkgs.

```bazel
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  name = "nixpkgs_config_cc",
)
```

This will select the default `stdenv.cc` package as the compiler, drawing
auxiliary tools from `stdenv.cc.bintools`. However, one can write a little bit of
Nix to configure this:

```bazel
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  attribute_path = "gcc11",
  name = "nixpkgs_config_cc",
)
```

`(import <nixpkgs> {})` loads the entire package set into an attribute set
(Nix's equivalent of a record), and `.gcc11` selects one value from it. It is
possible to customize the compiler further using more Nix if desired: you could,
for instance, point Nix to a custom fork of Clang containing support for a new
architecture, and have everything work seamlessly.

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

Now `bazel build` and `bazel run` should use this toolchain by
default for C/C++ compilation. This can be verified using Bazel's
`--toolchain_resolution_debug` switch:

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

# Working from a Nix-provided developer environment

Although we've made Bazel partially reproducible with the steps we've taken so
far, we don't yet have a guarantee that our builds are not influenced by the
global environment. Bazel has various hardcoded dependencies that can catch
users off-guard. For example, you can remove `.bazelrc` and rerun `bazel run`,
and everything will work just fine: Bazel will simply fall back to
`@local_config_cc`, because it's perfectly happy to use the C++ compiler
executables that are still on the PATH.

To mitigate this, we can use Nix to create a hermetic shell environment. This
will provide the exact dependencies that developers need, and nothing else. As
alluded to before, this is a similar concept to Python virtualenvs and other
similar language-specific tools, except with unified support for system
dependencies and language-specific dependencies across many different languages.

The `nix-shell` command we used to get a Nix-provided Bazel was the simplest
example of a Nix developer environment (one that simply added Bazel to the
environment), but they can be much more sophisticated. We can create development
environments that all contributors on a project can use with zero setup. When in
the shell, the user has access to consistent versions of libraries for whichever
languages are used in the project, as well as for system dependencies.

To get started, put the following code in a file named `flake.nix` at the root
of the repository:

```nix
{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    # For every platform that Nix supports, we ...
    flake-utils.lib.eachDefaultSystem (system:
      # ... get the package set for this particular platform ...
      let pkgs = import nixpkgs { inherit system; };
      in {
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

(For more about the `flake.nix` format, [this][flake-post] series of articles on
the Tweag blog may be helpful.)

We've also removed the "default" system-wide CC toolchain. The usual way to
define a development shell is with the commonly-used `mkShell` Nix function,
which creates a development shell with a given set of available dependencies
_and_ a default CC toolchain. We've replaced it with `mkShellNoCC`, which, as
the name suggests, does the same job but without implicitly making a CC
toolchain available. This means it's no longer possible to unintentionally use
`@local_config_cc`, as that toolchain won't be able to find the global binaries
it wants and will fail to work.

Now developers on different platforms can enter a development environment by
running `nix develop`, and this environment will be consistent across platforms.
This can be made even more seamless by using [direnv](direnv), which has support
for the `flake.nix` file we used to describe the development shell.

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
