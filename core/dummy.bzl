load("@nixpkgs_repositories//:defs.bzl", "dummy")

def _dummy_repo_impl(repository_ctx):
    print("DUMMY", dummy)
    defs = 'copied_dummy = {}'.format(repr(dummy))
    repository_ctx.file("defs.bzl", defs, executable=False)
    repository_ctx.file("BUILD.bazel", "", executable=False)

_dummy_repo = repository_rule(
    _dummy_repo_impl
)

def _copy_dummy_impl(module_ctx):
    print("DUMMY", dummy)
    defs = 'copied_dummy = {}'.format(repr(dummy))
    module_ctx.file("defs.bzl", defs, executable=False)
    module_ctx.file("BUILD.bazel", "", executable=False)
    _dummy_repo(name = "nixpkgs_dummy")

copy_dummy = module_extension(
    _copy_dummy_impl,
)
