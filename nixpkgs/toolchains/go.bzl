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
    """
    Use go toolchain from Nixpkgs. Will fail if not a nix-based platform.

    By default rules_go configures go toolchain to be downloaded as binaries (which doesn't work on NixOS),
    there is a way to tell rules_go to look into environment and find local go binary which is not hermetic.
    This command allows to setup hermetic go sdk from Nixpkgs, which should be considerate as best practice.

    Note that nix package must provide full go sdk at the root of package instead of in $out/share/go
    And also provide an empty normal file named PACKAGE_ROOT at the root of package
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
