load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load("@rules_nixpkgs_core//:util.bzl", "ensure_constraints")
load(
    "//private:common.bzl",
    "DEFAULT_PLATFORMS_MAPPING",
    "nixpkgs_nodejs",
)

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
    nixpkgs_nodejs(
        name = name,
        nix_platform = nix_platform,
        attribute_path = attribute_path,
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
