# TODO[AH] Push this into a load from JSON file within nixpkgs_package to avoid
#   the dependency between the packages module extension and a file generated
#   due to the repositories module extension.
#
#   Loading extension generated files into other extensions can lead to
#   undetected dependency cycles and lost tags:
#   https://github.com/bazelbuild/bazel/issues/17564
load("@nixpkgs_repositories//:defs.bzl", "get_nixpkgs_repository")
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
    module_packages = {}  # module_name -> tag_name -> repository_name

    # TODO[AH]: Deduplicate with repositories.bzl
    def _parse_tag_repository(repository):
        tag_name, repository_name = repository.split(":", 1)
        if tag_name == "" or repository_name == "":
            fail("INTERNAL ERROR: Malformed module package `{}`.".format(repository))
        return tag_name, repository_name

    def _add_module(module_name):
        if module_name in module_packages:
            fail("INTERNAL ERROR: Duplicate module encountered: `{}`.".format(module_name))
        module_packages[module_name] = {}

    def _add_module_package(module_name, tag_name, repository_name):
        if tag_name in module_packages[module_name]:
            fail("INTERNAL ERROR: Duplicate tag encountered: `{}` requested by module `{}`.".format(tag_name, module_name))
        module_packages[module_name][tag_name] = repository_name

    for module_name, tag_repositories in repository_ctx.attr.module_packages.items():
        _add_module(module_name)
        for tag_repository in tag_repositories:
            tag_name, repository_name = _parse_tag_repository(tag_repository)
            _add_module_package(module_name, tag_name, repository_name)

    print("MODULE_PACKAGES", module_packages)

    defs = """\
# TODO[AH] Infer module_name if possible.
#   Perhaps using `native.package_relative_label`?
#   See https://github.com/bazelbuild/bazel/commit/845291b718502361db22a67a9a4cff692b099d6d
def get_nixpkgs_package(module_name, tag_name, target):
    if not module_name in _packages:
        fail("Module `{}` requested nixpkgs package `{}` but did not define any package tags.".format(module_name, tag_name))
    if not tag_name in _packages[module_name]:
        fail("Module `{}` requested nixpkgs package `{}` but did not define a corresponding package tag.".format(module_name, tag_name))
    repository_name = _packages[module_name][tag_name]
    # TODO[AH] Verify that `target` is well-formed.
    return Label("@{}{}".format(repository_name, target))

"""
    defs += "_packages = {}".format(repr(module_packages))
    repository_ctx.file("defs.bzl", defs, executable=False)
    repository_ctx.file("BUILD.bazel", "", executable=False)

_all_packages = repository_rule(
    _all_packages_impl,
    attrs = {
        "module_packages": attr.string_list_dict(doc = "`module_name -> tag_name:repository_name`"),
    },
)

def _module_name(module):
    # TODO[AH]: Deduplicate with repositories.bzl
    # TODO[AH]: Handle collisions due to multi-version modules.
    return module.name

def _repository_name(module, tag_name):
    # TODO[AH]: Deduplicate with repositories.bzl
    # TODO[AH]: Choose a more robust naming scheme and handle collisions.
    return "{}_{}".format(_module_name(module), tag_name)

def _repository_label(repository_name):
    # TODO[AH]: Deduplicate with repositories.bzl
    return "@{name}//:{name}".format(name = repository_name)

def _packages_impl(module_ctx):
    module_packages = {}  # module_name -> tag_name -> repository_name

    # TODO[AH]: Deduplicate with repositories.bzl
    def _encode_tag_repository(tag_name, repository_name):
        return tag_name + ":" + repository_name

    def _add_module(module, module_name):
        if module_name in module_packages:
            fail("Duplicate module encountered: `{}` (module `{}` version `{}`).".format(module_name, module.name, module.version))
        module_packages[module_name] = {}

    def _add_module_package(module, tag_type, module_name, tag_name, repository_name):
        if tag_name in module_packages[module_name]:
            fail("Duplicate tag encountered: `{}` requested by module `{}` as {}.".format(tag_name, module_name, tag_type))
        module_packages[module_name][tag_name] = repository_name

    def _module_packages_attribute():
        result = {}
        for module_name, tags in module_packages.items():
            result[module_name] = []
            for tag_name, repository_name in tags.items():
                result[module_name].append(_encode_tag_repository(tag_name, repository_name))
        return result

    for module in module_ctx.modules:
        module_name = _module_name(module)
        _add_module(module, module_name)

        tag_type = "attribute"
        for tag in getattr(module.tags, tag_type):
            repository_name = _repository_name(module, tag.name)
            repository_label = _repository_label(repository_name)
            print("MODULE", module_name, "TAG", tag_type, tag.name, "REPOSITORY", repository_name)

            _add_module_package(module, tag_type, module_name, tag.name, repository_name)

            nixpkgs_package(
                name = repository_name,
                attribute_path = tag.path,
                repository = get_nixpkgs_repository(module_name, tag.repository),
            )

    print("MODULE_PACKAGES", _module_packages_attribute())

    _all_packages(
        name = "nixpkgs_packages",
        module_packages = _module_packages_attribute(),
    )

packages = module_extension(
    _packages_impl,
    tag_classes = {
        "attribute": _attribute_tag,
    },
)
