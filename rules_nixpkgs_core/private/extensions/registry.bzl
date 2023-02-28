"""Defines a registry for Bazel modules and associated external repositories.

The registry can be used to generate a hub module that exposes external
repositories that were generated as a consequence of a Bazel module requesting
a tag from a Bazel module extension.

Methods:

  - `registry.make(name)`: Create a new registry.

      Args:
        name: String, Assign a descriptive name for error reporting.

      Returns:
        Registry object, pass it to other functions of `registry`.

  - `registry.add_module(registry, module)`: Add a new module to the registry.

      You need to call `add_module` before you can call `new_repository`.

      Args:
        registry: Registry object.
        module: Module object, the module to add to the registry.

  - `registry.new_repository(registry, module, name)`: Allocate a new external workspace.

      This generates a fresh name for an external workspace and registers it
      for the given module under the given name.

      Args:
        registry: Registry object.
        module: Module object, register the workspace for this module.
        name: String, register the workspace under this name within the scope of the module.

      Returns:
        String, a unique name for the external workspace. You can use this name
        to create the external workspace by invoking a repository rule.

  - `registry.all_repositories(registry, *, name, getter_name)`: Generate a hub repository.

      Generates a central external workspace that exposes the external
      workspaces to the corresponding modules through an accessor function, see
      "Generated getter" below.

      Args:
        registry: Registry object.
        name: String, A unique name for the external workspace.
        getter_name: String, The name of the generated accessor function.

  - Generated getter `(module_name, module_version, name, label)`: Obtain a registered workspace.

      This function is generated in the `all_repositories` workspace.

      Args:
        module_name: String, the name of the module requesting a repository.
        module_version: String, the version of the module requesting a repository.
        name: String, the name of the repository being requested.
        label: String, a label to resolve within the requested repository.

      Returns:
        Label, the resolved label in the requested repository.
"""

def _key(module):
    # Using the name alone causes collisions on multi version overrides.
    # return module.name
    # Including the version has the downside that users must keep the version
    # in sync on the call-site.
    return "{}~{}".format(module.name, module.version)
    # Ideally, Bazel would provide a unique identifier on the module object
    # that is also accessible from within macros called within that module.
    # In the absense of that we can use a user provided tag like a label to the
    # `MODULE.bazel` file.

def _descriptive_name(module):
    if module.version:
        return "{} {}".format(module.name, module.version)
    else:
        return module.name

def _make(name):
    return struct(
        name = name,
        modules = {},
        repositories = {},
        module_repositories = {},
    )

def _add_module(registry, module):
    key = _key(module)
    name = _descriptive_name(module)

    if key in registry.modules:
        fail("Duplicate module '{}' in registry '{}'. The key '{}' is already used for '{}'".format(
            name,
            registry.name,
            key,
            registry.modules[key],
        ))

    registry.modules[key] = name
    registry.module_repositories[key] = {}

def _get_module_key(registry, module):
    key = _key(module)

    if not key in registry.modules:
        fail("Module '{}' is not registered in '{}'. It was expected under the key '{}'.".format(
            _descriptive_name(module),
            registry.name,
            key,
        ))

    return key

_MAX_COLLISIONS = 1000

def _fresh_repository_name(registry, name):
    for i in range(0, _MAX_COLLISIONS):
        if i == 0:
            candidate = name
        else:
            candidate = "{}_{}".format(name, str(i))
        if not candidate in registry.repositories:
            return candidate

    fail("Too many repositories requested under the name '{}' in registry '{}'.".format(
        name,
        registry.name,
    ))

def _new_repository(registry, module, name):
    key = _get_module_key(registry, module)

    if name in registry.module_repositories[key]:
        fail("Duplicate repository '{}' requested for module '{}' in registry '{}'.".format(
            name,
            registry.modules[key],
            registry.name,
        ))

    repo_name = _fresh_repository_name(registry, "{}_{}".format(
        module.name,
        name,
    ))

    registry.repositories[repo_name] = None
    registry.module_repositories[key][name] = repo_name

    return repo_name

def _all_repositories_impl(repository_ctx):
    module_repositories = {}
    for mod, repos in repository_ctx.attr.module_repositories.items():
        module_repositories[mod] = {}
        for repo in repos:
            tag_name, repo_name = repo.split(":", 1)
            module_repositories[mod][tag_name] = repo_name
    defs = """\
def {getter_name}(module_name, module_version, tag_name, label):
    key = "{{}}~{{}}".format(module_name, module_version)
    if not key in _modules:
        fail("Unknown module '{{}} {{}}'.".format(module_name, module_version))
    description = _modules[key]
    if not tag_name in _module_repositories[key]:
        fail("Unknown repository '{{}}' for module '{{}}'.".format(tag_name, description))
    repo_name = _module_repositories[key][tag_name]
    return Label("@" + repo_name).relative(label)

_modules = {modules}
_module_repositories = {module_repositories}
""".format(
        getter_name = repository_ctx.attr.getter_name,
        modules = repr(repository_ctx.attr.modules),
        module_repositories = repr(module_repositories),
    )
    repository_ctx.file("defs.bzl", defs, executable = False)
    repository_ctx.file("BUILD.bazel", "", executable = False)

_all_repositories_rule = repository_rule(
    _all_repositories_impl,
    attrs = {
        "getter_name": attr.string(mandatory = True),
        "modules": attr.string_dict(mandatory = True),
        "module_repositories": attr.string_list_dict(mandatory = True),
    },
)

def _all_repositories(registry, *, name, getter_name):
    _all_repositories_rule(
        name = name,
        getter_name = getter_name,
        modules = registry.modules,
        module_repositories = {
            mod: [
                "{}:{}".format(name, repo_name)
                for name, repo_name in repos.items()
            ]
            for mod, repos in registry.module_repositories.items()
        },
    )

registry = struct(
    make = _make,
    add_module = _add_module,
    new_repository = _new_repository,
    all_repositories = _all_repositories,
)
