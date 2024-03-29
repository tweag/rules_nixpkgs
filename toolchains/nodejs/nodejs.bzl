load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load("@rules_nixpkgs_core//:util.bzl", "ensure_constraints")
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

_nodejs_nix_content = """\
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

_nodejs_nix_toolchain = """
toolchain(
    name = "nodejs_nix",
    toolchain = "@{toolchain_repo}//:nodejs_nix_impl",
    toolchain_type = "@rules_nodejs//nodejs:toolchain_type",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)
"""

def _nixpkgs_nodejs_toolchain_impl(repository_ctx):
    exec_constraints, target_constraints = ensure_constraints(repository_ctx)
    repository_ctx.file(
        "BUILD.bazel",
        executable = False,
        content = _nodejs_nix_toolchain.format(
            toolchain_repo = repository_ctx.attr.toolchain_repo,
            exec_constraints = exec_constraints,
            target_constraints = target_constraints,
        ),
    )

_nixpkgs_nodejs_toolchain = repository_rule(
  _nixpkgs_nodejs_toolchain_impl,
  attrs = {
    "toolchain_repo": attr.string(),
    "exec_constraints": attr.string_list(),
    "target_constraints": attr.string_list(),
  },
)

def nixpkgs_nodejs_configure(
  name = "nixpkgs_nodejs",
  attribute_path = "nodejs",
  repository = None,
  repositories = {},
  nix_platform = None,
  nix_file = None,
  nix_file_content = None,
  nix_file_deps = None,
  nixopts = [],
  fail_not_supported = True,
  quiet = False,
  exec_constraints = None,
  target_constraints = None,
  register = True,
):
    if attribute_path == None:
        fail("'attribute_path' is required.", "attribute_path")
    if not nix_file and not nix_file_content:
      nix_file_content = _nodejs_nix_content.format(
        attribute_path = attribute_path,
        nix_platform = "builtins.currentSystem" if nix_platform == None else repr(nix_platform),
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

    _nixpkgs_nodejs_toolchain(
      name = "{}_toolchain".format(name),
      toolchain_repo = name,
      exec_constraints = exec_constraints,
      target_constraints = target_constraints,
    )

    if register:
        native.register_toolchains("@{}_toolchain//:nodejs_nix".format(name))

def nixpkgs_nodejs_configure_platforms(
  name = "nixpkgs_nodejs",
  platforms_mapping = DEFAULT_PLATFORMS_MAPPING,
  attribute_path = "nodejs",
  repository = None,
  repositories = {},
  nix_platform = None,
  nix_file = None,
  nix_file_content = None,
  nix_file_deps = None,
  nixopts = [],
  fail_not_supported = True,
  quiet = False,
  exec_constraints = None,
  target_constraints = None,
  register = True,
  **kwargs,
):
    """Runs nixpkgs_nodejs_configure for each platform.

    Since rules_nodejs adds platform suffix to repository name, this can be helpful
    if one wants to use npm_install and reference js dependencies from npm repo.
    See the example directory.

    Args:
      platforms_mapping: struct describing mapping between nix platform and rules_nodejs bazel platform with
        target and exec constraints
    """
    for nix_platform, bazel_platform in platforms_mapping.items():
        nixpkgs_nodejs_configure(
            name = "{}_{}".format(name, bazel_platform.rules_nodejs_platform),
            attribute_path = attribute_path,
            repository = repository,
            repositories = repositories,
            nix_platform = nix_platform,
            nix_file = nix_file,
            nix_file_content = nix_file_content,
            nix_file_deps = nix_file_deps,
            nixopts = nixopts,
            fail_not_supported = fail_not_supported,
            quiet = quiet,
            exec_constraints = bazel_platform.exec_constraints,
            target_constraints = bazel_platform.target_constraints,
            register = register,
            **kwargs,
        )
