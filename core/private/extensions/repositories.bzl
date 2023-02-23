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
    repositories = {}  # repository_name -> repository_label
    module_repositories = {}  # module_name -> tag_name -> struct(repository_name, repository_label)

    def _parse_tag_repository(repository):
        tag_name, repository_name = repository.split(":", 1)
        if tag_name == "" or repository_name == "":
            fail("INTERNAL ERROR: Malformed module repository `{}`.".format(repository))
        return tag_name, repository_name

    def _add_repository(repository_name, repository_label):
        if repository_name in repositories:
            fail("INTERNAL ERROR: Duplicate repository encountered: `{}`.".format(repository_name))
        repositories[repository_name] = repository_label

    def _add_module(module_name):
        if module_name in module_repositories:
            fail("INTERNAL ERROR: Duplicate module encountered: `{}`.".format(module_name))
        module_repositories[module_name] = {}

    def _add_module_repository(module_name, tag_name, repository_name):
        if tag_name in module_repositories[module_name]:
            fail("INTERNAL ERROR: Duplicate tag encountered: `{}` requested by module `{}`.".format(tag_name, module_name))
        if not repository_name in repositories:
            fail("INTERNAL ERROR: Unknown repository encountered: `{}` requested by module `{}`.".format(repository_name, module_name))
        print("LABEL", repositories[repository_name])
        print("  STR", str(repositories[repository_name]))
        print(" REPR", repr(repositories[repository_name]))
        module_repositories[module_name][tag_name] = struct(
            repository_name = repository_name,
            repository_label = str(repositories[repository_name]),
        )

    for repository_label, repository_name in repository_ctx.attr.repositories.items():
        _add_repository(repository_name, repository_label)

    for module_name, tag_repositories in repository_ctx.attr.module_repositories.items():
        _add_module(module_name)
        for tag_repository in tag_repositories:
            tag_name, repository_name = _parse_tag_repository(tag_repository)
            _add_module_repository(module_name, tag_name, repository_name)

    print("REPOSITORIES", repositories)
    print("MODULE_REPOSITORIES", module_repositories)

    defs = "repositories = {}".format(repr(module_repositories))
    repository_ctx.file("defs.bzl", defs, executable=False)
    repository_ctx.file("BUILD.bazel", "", executable=False)

_all_repositories = repository_rule(
    _all_repositories_impl,
    attrs = {
        "repositories": attr.string_dict(doc = "`repository_label -> repository_name`"),
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
    repositories = {}  # repository_label -> repository_name
    module_repositories = {}  # module_name -> tag_name -> repository_name

    def _encode_tag_repository(tag_name, repository_name):
        return tag_name + ":" + repository_name

    def _add_repository(module, tag_type, tag_name, repository_name, repository_label):
        if repository_label in repositories:
            fail("Duplicate repository encountered: `{}` requested by module `{}` as {} `{}`.".format(repository_label, module.name, tag_type, tag_name))
        repositories[repository_label] = repository_name

    def _add_module(module, module_name):
        if module_name in module_repositories:
            fail("Duplicate module encountered: `{}` (module `{}` version `{}`).".format(module_name, module.name, module.version))
        module_repositories[module_name] = {}

    def _add_module_repository(module, tag_type, module_name, tag_name, repository_name):
        if tag_name in module_repositories[module_name]:
            fail("Duplicate tag encountered: `{}` requested by module `{}` as {}.".format(tag_name, module_name, tag_type))
        module_repositories[module_name][tag_name] = repository_name

    def _repositories_attribute():
        return repositories

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
            _add_repository(module, tag_type, tag.name, repository_name, repository_label)

            nixpkgs_local_repository(
                name = repository_name,
                nix_file = tag.file,
                nix_file_deps = tag.file_deps,
            )

    print("REPOSITORIES", _repositories_attribute())
    print("MODULE_REPOSITORIES", _module_repositories_attribute())

    _all_repositories(
        name = "nixpkgs_repositories",
        repositories = _repositories_attribute(),
        module_repositories = _module_repositories_attribute(),
    )

repositories = module_extension(
    _repositories_impl,
    tag_classes = {
        "file": _repository_file_tag,
    },
)
