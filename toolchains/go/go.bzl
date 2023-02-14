"""<!-- Edit the docstring in `toolchains/go/go.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules for importing a Go toolchain from Nixpkgs.

## Rules

* [nixpkgs_go_configure](#nixpkgs_go_configure)
"""

load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load("@io_bazel_rules_go//go/private:platforms.bzl", "PLATFORMS")

def _detect_host_platform(ctx):
    """Copied from `rules_go`, since we have no other way to determine the proper `goarch` value.
    https://github.com/bazelbuild/rules_go/blob/728a9e1874bc965b05c415d7f6b332a86ac35102/go/private/sdk.bzl#L239
    """
    if ctx.os.name == "linux":
        goos, goarch = "linux", "amd64"
        res = ctx.execute(["uname", "-p"])
        if res.return_code == 0:
            uname = res.stdout.strip()
            if uname == "s390x":
                goarch = "s390x"
            elif uname == "i686":
                goarch = "386"

        # uname -p is not working on Aarch64 boards
        # or for ppc64le on some distros
        res = ctx.execute(["uname", "-m"])
        if res.return_code == 0:
            uname = res.stdout.strip()
            if uname == "aarch64":
                goarch = "arm64"
            elif uname == "armv6l":
                goarch = "arm"
            elif uname == "armv7l":
                goarch = "arm"
            elif uname == "ppc64le":
                goarch = "ppc64le"

        # Default to amd64 when uname doesn't return a known value.

    elif ctx.os.name == "mac os x":
        goos, goarch = "darwin", "amd64"

        res = ctx.execute(["uname", "-m"])
        if res.return_code == 0:
            uname = res.stdout.strip()
            if uname == "arm64":
                goarch = "arm64"

        # Default to amd64 when uname doesn't return a known value.

    elif ctx.os.name.startswith("windows"):
        goos, goarch = "windows", "amd64"
    elif ctx.os.name == "freebsd":
        goos, goarch = "freebsd", "amd64"
    else:
        fail("Unsupported operating system: " + ctx.os.name)

    return goos, goarch

go_helpers_build = """
load("@io_bazel_rules_go//go:def.bzl", "go_sdk")

def go_sdk_for_arch():
    native.filegroup(
        name = "libs",
        srcs = native.glob(
            ["pkg/{goos}_{goarch}/**/*.a"],
            exclude = ["pkg/{goos}_{goarch}/**/cmd/**"],
        ),
    )

    go_sdk(
        name = "go_sdk",
        goos = "{goos}",
        goarch = "{goarch}",
        root_file = "ROOT",
        package_list = ":package_list",
        libs = [":libs"],
        headers = [":headers"],
        srcs = [":srcs"],
        tools = [":tools"],
        go = "bin/go{exe}",
    )
"""

def _nixpkgs_go_helpers_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", executable = False, content = "")
    goos, goarch = _detect_host_platform(repository_ctx)
    content = go_helpers_build.format(
        goos = goos,
        goarch = goarch,
        exe = ".exe" if goos == "windows" else "",
    )
    repository_ctx.file("go_sdk.bzl", executable = False, content = content)

nixpkgs_go_helpers = repository_rule(
    implementation = _nixpkgs_go_helpers_impl,
)

go_toolchain_func = """
load("@io_bazel_rules_go//go/private:platforms.bzl", "PLATFORMS")
load("@io_bazel_rules_go//go:def.bzl", "go_toolchain")

def declare_toolchains(host_goos, host_goarch):
    for p in [p for p in PLATFORMS if not p.cgo]:
        link_flags = []
        cgo_link_flags = []
        if host_goos == "darwin":
            cgo_link_flags.extend(["-shared", "-Wl,-all_load"])
        if host_goos == "linux":
            cgo_link_flags.append("-Wl,-whole-archive")
        toolchain_name = "toolchain_go_" + p.name
        impl_name = toolchain_name + "-impl"
        cgo_constraints = (
            "@io_bazel_rules_go//go/toolchain:cgo_off",
            "@io_bazel_rules_go//go/toolchain:cgo_on",
        )
        constraints = [c for c in p.constraints if c not in cgo_constraints]
        go_toolchain(
            name = impl_name,
            goos = p.goos,
            goarch = p.goarch,
            sdk = "@{sdk_repo}//:go_sdk",
            builder = "@{sdk_repo}//:builder",
            link_flags = link_flags,
            cgo_link_flags = cgo_link_flags,
            visibility = ["//visibility:public"],
        )
        native.toolchain(
            name = toolchain_name,
            toolchain_type = "@io_bazel_rules_go//go:toolchain",
            exec_compatible_with = [
                "@io_bazel_rules_go//go/toolchain:" + host_goos,
                "@io_bazel_rules_go//go/toolchain:" + host_goarch,
                "@rules_nixpkgs_core//constraints:support_nix",
            ],
            target_compatible_with = constraints,
            toolchain = ":" + impl_name,
        )
"""

go_toolchain_build = """
load("//:toolchain.bzl", "declare_toolchains")

declare_toolchains("{goos}", "{goarch}")
"""

def _nixpkgs_go_toolchain_impl(repository_ctx):
    goos, goarch = _detect_host_platform(repository_ctx)
    content = go_toolchain_func.format(
        sdk_repo = repository_ctx.attr.sdk_repo,
    )
    build_content = go_toolchain_build.format(
        goos = goos,
        goarch = goarch,
    )
    repository_ctx.file("toolchain.bzl", executable = False, content = content)
    repository_ctx.file("BUILD.bazel", executable = False, content = build_content)

nixpkgs_go_toolchain = repository_rule(
    implementation = _nixpkgs_go_toolchain_impl,
    attrs = {
        "sdk_repo": attr.string(
            doc = "name of the nixpkgs_package repository defining the go sdk",
        ),
    },
    doc = """
    Set up the Go SDK
    """,
)

go_sdk_build = """
load("@io_bazel_rules_go//go/private/rules:binary.bzl", "go_tool_binary")
load("@io_bazel_rules_go//go/private/rules:sdk.bzl", "package_list")
load("@io_bazel_rules_go//go:def.bzl", "go_sdk")
load("@{helpers}//:go_sdk.bzl", "go_sdk_for_arch")

package(default_visibility = ["//visibility:public"])

go_sdk_for_arch()

filegroup(
    name = "headers",
    srcs = glob(["pkg/include/*.h"]),
)

filegroup(
    name = "srcs",
    srcs = glob(["src/**"]),
)

filegroup(
    name = "tools",
    srcs = glob(["pkg/tool/**", "bin/gofmt*"])
)

go_tool_binary(
    name = "builder",
    srcs = ["@io_bazel_rules_go//go/tools/builders:builder_srcs"],
    sdk = ":go_sdk",
)

package_list(
    name = "package_list",
    srcs = [":srcs"],
    root_file = "ROOT",
    out = "packages.txt",
)

filegroup(
    name = "files",
    srcs = glob([
        "bin/go*",
        "src/**",
        "pkg/**",
    ]),
)

exports_files(
    ["lib/time/zoneinfo.zip"],
    visibility = ["//visibility:public"],
)
"""

def nixpkgs_go_configure(
        sdk_name = "go_sdk",
        repository = None,
        repositories = {},
        attribute_path = "go",
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = [],
        fail_not_supported = True,
        quiet = False,
        register = True):
    """Use go toolchain from Nixpkgs.

    By default rules_go configures the go toolchain to be downloaded as binaries (which doesn't work on NixOS).
    There is a way to tell rules_go to look into environment and find local go binary which is not hermetic.
    This command allows to setup a hermetic go sdk from Nixpkgs, which should be considered as best practice.
    Cross toolchains are declared and registered for each entry in the `PLATFORMS` constant in `rules_go`.

    Note that the nix package must provide a full go sdk at the root of the package instead of in `$out/share/go`,
    and also provide an empty normal file named `ROOT` at the root of package.

    #### Example

      ```bzl
      nixpkgs_go_configure(repository = "@nixpkgs//:default.nix")
      ```

      Example (optional nix support when go is a transitive dependency):

      ```bzl
      # .bazel-lib/nixos-support.bzl
      def _has_nix(ctx):
          return ctx.which("nix-build") != None

      def _gen_imports_impl(ctx):
          ctx.file("BUILD", "")

          imports_for_nix = \"""
              load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl", "nixpkgs_go_configure")

              def fix_go():
                  nixpkgs_go_configure(repository = "@nixpkgs")
          \"""
          imports_for_non_nix = \"""
              def fix_go():
                  # if go isn't transitive you'll need to add call to go_register_toolchains here
                  pass
          \"""

          if _has_nix(ctx):
              ctx.file("imports.bzl", imports_for_nix)
          else:
              ctx.file("imports.bzl", imports_for_non_nix)

      _gen_imports = repository_rule(
          implementation = _gen_imports_impl,
          attrs = dict(),
      )

      def gen_imports():
          _gen_imports(
              name = "nixos_support",
          )

      # WORKSPACE

      // ...
      http_archive(name = "io_tweag_rules_nixpkgs", ...)
      // ...
      local_repository(
          name = "bazel_lib",
          path = ".bazel-lib",
      )
      load("@bazel_lib//:nixos-support.bzl", "gen_imports")
      gen_imports()
      load("@nixos_support//:imports.bzl", "fix_go")
      fix_go()
      ```

    Args:
      sdk_name: Go sdk name to pass to rules_go
      attribute_path: The nixpkgs attribute path for the `go` to use.
      nix_file: An expression for a Nix environment derivation. The environment should expose the whole go SDK (`bin`, `src`, ...) at the root of package. It also must contain a `ROOT` file in the root of pacakge. Takes precedence over attribute_path.
      nix_file_deps: Dependencies of `nix_file` if any.
      nix_file_content: An expression for a Nix environment derivation. Takes precedence over attribute_path.
      repository: A repository label identifying which Nixpkgs to use. Equivalent to `repositories = { "nixpkgs": ...}`.
      repositories: A dictionary mapping `NIX_PATH` entries to repository labels.

        Setting it to
        ```
        repositories = { "myrepo" : "//:myrepo" }
        ```
        for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.

        Specify one of `path` or `repositories`.
      fail_not_supported: See [`nixpkgs_package`](#nixpkgs_package-fail_not_supported).
      quiet: Whether to hide the output of the Nix command.
      register: Automatically register the generated toolchain if set to True.
    """

    if not nix_file and not nix_file_content:
        nix_file_content = """
           with import <nixpkgs> {{ config = {{}}; overlays = []; }}; buildEnv {{
              name = "bazel-go-toolchain";
              paths = [
                {attribute_path}
              ];
              postBuild = ''
                touch $out/ROOT
                ln -s $out/share/go/{{api,doc,lib,misc,pkg,src}} $out/
              '';
            }}
        """.format(attribute_path = attribute_path)

    helpers_repo = sdk_name + "_helpers"
    nixpkgs_go_helpers(
        name = helpers_repo,
    )
    nixpkgs_package(
        name = sdk_name,
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        build_file_content = go_sdk_build.format(
            helpers = helpers_repo,
        ),
        nixopts = nixopts,
        fail_not_supported = fail_not_supported,
        quiet = quiet,
    )
    toolchains_repo = sdk_name + "_toolchains"
    nixpkgs_go_toolchain(
        name = toolchains_repo,
        sdk_repo = sdk_name,
    )
    if register:
        for p in [p for p in PLATFORMS if not p.cgo]:
            native.register_toolchains("@{}//:toolchain_go_{}".format(toolchains_repo, p.name))
