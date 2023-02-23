# TODO[AH] Push this into a load from JSON file within nixpkgs_package to avoid
#   the dependency between the packages module extension and a file generated
#   due to the repositories module extension.
#
#   Loading extension generated files into other extensions can lead to
#   undetected dependency cycles and lost tags:
#   https://github.com/bazelbuild/bazel/issues/17564
load("@nixpkgs_repositories//:defs.bzl", "repositories")
load("//:nixpkgs.bzl", "nixpkgs_package")

_attribute_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "TODO",
            mandatory = True,
        ),
        "path": attr.string(
            doc = "The attribute path into the top-level Nix expression of the repository.",
            # TODO[AH] optional and default to name?
            mandatory = True,
        ),
        "repository": attr.string(
            doc = "The nixpkgs repository to take this package from.",
            # TODO[AH] optional and default to nixpkgs?
            mandatory = True,
        ),
    },
)

def _all_packages_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", "", executable=False)

_all_packages = repository_rule(
    _all_packages_impl,
    attrs = {
    },
)

def _module_name(module):
    # TODO[AH]: Deduplicate with repositories.bzl%_module_name
    # TODO[AH]: Handle collisions due to multi-version modules.
    return module.name

def _repository_name(module, tag_name):
    # TODO[AH]: Deduplicate with repositories.bzl%_module_name
    # TODO[AH]: Choose a more robust naming scheme and handle collisions.
    return "{}_{}".format(_module_name(module), tag_name)

def _repository_label(repository_name):
    # TODO[AH]: Deduplicate with repositories.bzl%_module_name
    return "@{name}//:{name}".format(name = repository_name)

def _packages_impl(module_ctx):
    for module in module_ctx.modules:
        module_name = _module_name(module)

        tag_type = "attribute"
        for tag in getattr(module.tags, tag_type):
            repository_name = _repository_name(module, tag.name)
            repository_label = _repository_label(repository_name)
            print("MODULE", module_name, "TAG", tag_type, tag.name, "REPOSITORY", repository_name)

            if not module_name in repositories:
                fail("Module `{}` requested nixpkgs repository `{}` but did not define any repository tags.".format(module_name, tag.repository))
            if not tag.repository in repositories[module_name]:
                fail("Module `{}` requested nixpkgs repository `{}` but did not define a corresponding repository tag.".format(module_name, tag.repository))

            nixpkgs_package(
                name = repository_name,
                attribute_path = tag.path,
                repository = repositories[module_name][tag.repository].repository_label,
            )

    _all_packages(
        name = "nixpkgs_packages",
    )

packages = module_extension(
    _packages_impl,
    tag_classes = {
        "attribute": _attribute_tag,
    },
)
