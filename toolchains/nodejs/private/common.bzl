load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load("@rules_nodejs//nodejs/private:toolchains_repo.bzl", "PLATFORMS")


def _mk_mapping(rules_nodejs_platform_name):
    constraints = PLATFORMS[rules_nodejs_platform_name].compatible_with
    return struct(
        rules_nodejs_platform = rules_nodejs_platform_name,
        exec_constraints = constraints,
        target_constraints = constraints,
    )


# obtained (and matched) from:
# nixpkgs search: https://search.nixos.org/packages?channel=22.11&show=nodejs&from=0&size=50&sort=relevance&type=packages&query=nodejs
# rules_nodejs: https://github.com/bazelbuild/rules_nodejs/blob/a5755eb458c2dd8e0e2cf9b92d8304d9e77ea117/nodejs/private/toolchains_repo.bzl#L20
DEFAULT_PLATFORMS_MAPPING = {
  "aarch64-darwin": _mk_mapping("darwin_arm64"),
  "x86_64-linux": _mk_mapping("linux_amd64"),
  "x86_64-darwin": _mk_mapping("darwin_amd64"),
  "aarch64-linux": _mk_mapping("linux_arm64"),
}


NODEJS_NIX_FILE_CONTENT = """\
let
    pkgs = import <nixpkgs> {{ config = {{}}; overlays = []; system = {nix_platform}; }};
    nodejs = pkgs.{attribute_path};
in
pkgs.buildEnv {{
  extraOutputsToInstall = ["out" "bin" "lib"];
  name = "bazel-nodejs-toolchain";
  paths  = [ nodejs ];
  postBuild = ''
    touch $out/ROOT
    cat <<EOF > $out/BUILD

    filegroup(
        name = "nodejs",
        srcs = ["bin/node"],
        visibility = ["//visibility:public"],
    )

    load("@rules_nodejs//nodejs:toolchain.bzl", "node_toolchain")
    node_toolchain(
        name = "nodejs_nix_impl",
        target_tool = ":nodejs",
        visibility = ["//visibility:public"],
    )

    EOF
  '';
}}
"""


NODEJS_TOOLCHAIN_SNIPPET = """\
toolchain(
    name = {name},
    toolchain = {label},
    toolchain_type = "@rules_nodejs//nodejs:toolchain_type",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)
"""


def nodejs_nix_file_content(*, attribute_path, nix_platform = None):
    if nix_platform == None:
        nix_platform = "builtins.currentSystem"
    else:
        nix_platform = repr(nix_platform)

    return NODEJS_NIX_FILE_CONTENT.format(
        attribute_path = attribute_path,
        nix_platform = nix_platform,
    )


def nixpkgs_nodejs(
        *,
        name,
        nix_platform,
        attribute_path,
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = [],
        fail_not_supported = True,
        quiet = False):
    if attribute_path == None:
        fail("'attribute_path' is required.", "attribute_path")

    if not nix_file and not nix_file_content:
        nix_file_content = nodejs_nix_file_content(
            attribute_path = attribute_path,
            nix_platform = nix_platform,
        )

    nixpkgs_package(
        name = name,
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        nixopts = nixopts,
        fail_not_supported = fail_not_supported,
        quiet = quiet,
    )

def nodejs_toolchain(*, name, label, exec_constraints, target_constraints):
    return NODEJS_TOOLCHAIN_SNIPPET.format(
        name = repr(name),
        label = repr(label),
        exec_constraints = repr(exec_constraints),
        target_constraints = repr(target_constraints),
    )
