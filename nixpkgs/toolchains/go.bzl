"""Rules for importing a Go toolchain from Nixpkgs.

**NOTE: The following rules must be loaded from
`@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl` to avoid unnecessary
dependencies on rules_go for those who don't need go toolchain.
`io_bazel_rules_go` must be available for loading before loading of
`@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl`.**
"""

load(
    "@io_bazel_rules_go//go:deps.bzl",
    "go_wrap_sdk",
)
load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_package",
)

def nixpkgs_go_configure(
        sdk_name = "go_sdk",
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = []):
    """Use go toolchain from Nixpkgs. Will fail if not a nix-based platform.

    By default rules_go configures the go toolchain to be downloaded as binaries (which doesn't work on NixOS),
    there is a way to tell rules_go to look into environment and find local go binary which is not hermetic.
    This command allows to setup hermetic go sdk from Nixpkgs, which should be considerate as best practice.

    Note that the nix package must provide a full go sdk at the root of the package instead of in `$out/share/go`,
    and also provide an empty normal file named `PACKAGE_ROOT` at the root of package.

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
      nix_file: An expression for a Nix environment derivation. The environment should expose the whole go SDK (`bin`, `src`, ...) at the root of package. It also must contain a `PACKAGE_ROOT` file in the root of pacakge.
      nix_file_deps: Dependencies of `nix_file` if any.
      nix_file_content: An expression for a Nix environment derivation.
      repository: A repository label identifying which Nixpkgs to use. Equivalent to `repositories = { "nixpkgs": ...}`.
      repositories: A dictionary mapping `NIX_PATH` entries to repository labels.

        Setting it to
        ```
        repositories = { "myrepo" : "//:myrepo" }
        ```
        for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) in the nix manual for more information.

        Specify one of `path` or `repositories`.
    """

    if not nix_file and not nix_file_content:
        nix_file_content = """
            with import <nixpkgs> { config = {}; overlays = []; }; buildEnv {
              name = "bazel-go-toolchain";
              paths = [
                go
              ];
              postBuild = ''
                touch $out/PACKAGE_ROOT
                ln -s $out/share/go/{api,doc,lib,misc,pkg,src} $out/
              '';
            }
        """

    nixpkgs_package(
        name = "nixpkgs_go_toolchain",
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        build_file_content = """exports_files(glob(["**/*"]))""",
        nixopts = nixopts,
    )

    go_wrap_sdk(name = sdk_name, root_file = "@nixpkgs_go_toolchain//:PACKAGE_ROOT")
