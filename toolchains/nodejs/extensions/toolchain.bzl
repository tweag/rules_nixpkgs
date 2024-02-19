"""Defines the nix_nodejs module extension.
"""

_TOOLCHAINS_REPO = "nixpkgs_nodejs_toolchains"

def _toolchains_repo_impl(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        content = "",
        executable = False,
    )

_toolchains_repo = repository_rule(
    _toolchains_repo_impl,
    attrs = {
    },
)

def _nix_nodejs_impl(module_ctx):
    _toolchains_repo(
        name = _TOOLCHAINS_REPO,
    )

nix_nodejs = module_extension(
    _nix_nodejs_impl,
    tag_classes = {
    },
)
