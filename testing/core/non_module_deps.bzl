load(
    "//:nixpkgs_repositories.bzl",
    "nixpkgs_repositories",
)

def _non_module_deps_impl(ctx):
    nixpkgs_repositories()

non_module_deps = module_extension(
    implementation = _non_module_deps_impl,
)
