load("//:nixpkgs.bzl", "nixpkgs_local_repository")

_repository_file_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Reference this repository by `NAME` in other module tags or in Nix expressions using `<NAME>`.",
            mandatory = True,
        ),
        "file": attr.label(
            doc = "A Nix file that defines a nixpkgs repository.",
            allow_single_file = True,
            mandatory = True,
        ),
        "file_deps": attr.label_list(
            doc = "Other files needed to evaluate the Nix repository.",
            allow_files = True,
        ),
    },
)

def _all_repositories_impl(repository_ctx):
    module_repositories = {}  # module_name -> tag_name -> repository_name

    def _parse_tag_repository(repository):
        tag_name, repository_name = repository.split(":", 1)
        if tag_name == "" or repository_name == "":
            fail("INTERNAL ERROR: Malformed module repository `{}`.".format(repository))
        return tag_name, repository_name

    def _add_module(module_name):
        if module_name in module_repositories:
            fail("INTERNAL ERROR: Duplicate module encountered: `{}`.".format(module_name))
        module_repositories[module_name] = {}

    def _add_module_repository(module_name, tag_name, repository_name):
        if tag_name in module_repositories[module_name]:
            fail("INTERNAL ERROR: Duplicate tag encountered: `{}` requested by module `{}`.".format(tag_name, module_name))
        module_repositories[module_name][tag_name] = repository_name

    for module_name, tag_repositories in repository_ctx.attr.module_repositories.items():
        _add_module(module_name)
        for tag_repository in tag_repositories:
            tag_name, repository_name = _parse_tag_repository(tag_repository)
            _add_module_repository(module_name, tag_name, repository_name)

    print("MODULE_REPOSITORIES", module_repositories)

    defs = """\
def get_nixpkgs_repository(module_name, tag_name):
    if not module_name in _repositories:
        fail("Module `{}` requested nixpkgs repository `{}` but did not define any repository tags.".format(module_name, tag_name))
    if not tag_name in _repositories[module_name]:
        fail("Module `{}` requested nixpkgs repository `{}` but did not define a corresponding repository tag.".format(module_name, tag_name))
    repository_name = _repositories[module_name][tag_name]
    return Label("@{name}//:{name}".format(name = repository_name))

"""
    defs += "_repositories = {}".format(repr(module_repositories))
    repository_ctx.file("defs.bzl", defs, executable=False)
    repository_ctx.file("BUILD.bazel", "", executable=False)

_all_repositories = repository_rule(
    _all_repositories_impl,
    attrs = {
        "module_repositories": attr.string_list_dict(doc = "`module_name -> tag_name:repository_name`"),
    },
)

def _module_name(module):
    # TODO[AH]: Handle collisions due to multi-version modules.
    return module.name

def _repository_name(module, tag_name):
    # TODO[AH]: Choose a more robust naming scheme and handle collisions.
    return "{}_{}".format(_module_name(module), tag_name)

def _repository_label(repository_name):
    return "@{name}//:{name}".format(name = repository_name)

def _repositories_impl(module_ctx):
    module_repositories = {}  # module_name -> tag_name -> repository_name

    def _encode_tag_repository(tag_name, repository_name):
        return tag_name + ":" + repository_name

    def _add_module(module, module_name):
        if module_name in module_repositories:
            fail("Duplicate module encountered: `{}` (module `{}` version `{}`).".format(module_name, module.name, module.version))
        module_repositories[module_name] = {}

    def _add_module_repository(module, tag_type, module_name, tag_name, repository_name):
        if tag_name in module_repositories[module_name]:
            fail("Duplicate tag encountered: `{}` requested by module `{}` as {}.".format(tag_name, module_name, tag_type))
        module_repositories[module_name][tag_name] = repository_name

    def _module_repositories_attribute():
        result = {}
        for module_name, tags in module_repositories.items():
            result[module_name] = []
            for tag_name, repository_name in tags.items():
                result[module_name].append(_encode_tag_repository(tag_name, repository_name))
        return result

    for module in module_ctx.modules:
        module_name = _module_name(module)
        _add_module(module, module_name)

        tag_type = "file"
        for tag in getattr(module.tags, tag_type):
            repository_name = _repository_name(module, tag.name)
            repository_label = _repository_label(repository_name)

            _add_module_repository(module, tag_type, module_name, tag.name, repository_name)

            nixpkgs_local_repository(
                name = repository_name,
                nix_file = tag.file,
                nix_file_deps = tag.file_deps,
            )

    print("MODULE_REPOSITORIES", _module_repositories_attribute())

    _all_repositories(
        name = "nixpkgs_repositories",
        module_repositories = _module_repositories_attribute(),
    )

repositories = module_extension(
    _repositories_impl,
    tag_classes = {
        "file": _repository_file_tag,
    },
)
