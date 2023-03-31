"""This module implements a generic registry for hub repositories.
"""

load("@bazel_skylib//lib:partial.bzl", "partial")

_DUPLICATE_MODULE_ERROR = "Duplicate module '{desc}', previous version '{prev}'."
_DUPLICATE_LOCAL_REPO_ERROR = "Duplicate local repository '{name}', requested by module '{desc}'."
_DUPLICATE_GLOBAL_REPO_ERROR = "Duplicate global repository '{name}'."
_MODULE_NOT_FOUND_ERROR = "Module not found: '{key}'."
_LOCAL_REPO_NOT_FOUND_ERROR = "Local repository '{name}' not found, requested by module '{desc}'."
_GLOBAL_REPO_NOT_REGISTERED_ERROR = "Global repository '{name}' not registered, requested by module '{desc}'."

def _make_registry():
    """Create a new registry object.

    Returns:
      The registry object.
    """
    return struct(
        _modules = {},
        _global_repositories = {},
    )

def _module_key(name, version):
    """Generate a key to identify a module.

    Args:
      name: String, The name of the module.
      version: String, The version of the module.

    Returns:
      String, The generated key for the module.
    """

    # TODO[AH] Take the module version into account
    #   to support multi version overrides.
    return name

def _module_description(name, version):
    """Generate a human readable description for a module.

    Args:
      name: String, The name of the module.
      version: String, The version of the module.

    Returns:
      String, The generated description for the module.
    """
    if version:
        return "{} {}".format(name, version)
    else:
        return name

def _make_module(*, name, version, description):
    """Create a new module object.

    Args:
      name: String, The name of the module.
      version: String, The version of the module.
      description: String, The description of the module.

    Returns:
      The module object.
    """
    return struct(
        _name = name,
        _version = version,
        _description = description,
        _local_repositories = {},
        _global_repositories = {},
    )

def _add_module(r, *, name, version):
    """Register a new module.

    Args:
      r: The registry object.
      name: String, The name of the module to register.
      version: String, The version of the module to register.

    Returns:
      Tuple, the first element is the key to access the module in the registry,
      the second element is an error message in case of failure
      or None if successful.
    """
    key = _module_key(name, version)
    desc = _module_description(name, version)

    if key in r._modules:
        return None, _DUPLICATE_MODULE_ERROR.format(
            desc = desc,
            prev = r._modules[key]._version,
        )

    r._modules[key] = _make_module(
        name = name,
        version = version,
        description = desc,
    )

    return key, None

def _use_global_repo(r, *, key, name):
    """Register the dependency of a module on a global repository.

    Args:
      r: The registry object.
      key: String, The key of the module in the registry.
      name: String, The name of the global repository.

    Returns:
      Tuple, the first element is None,
      the second element is an error message in case of failure
      or None if successful.
    """
    module = r._modules.get(key)
    if module == None:
        return None, _MODULE_NOT_FOUND_ERROR.format(key = key)

    module._global_repositories[name] = True

    return None, None

def _add_local_repo(r, *, key, name, repo):
    """Register a new local repository for the module.

    Args:
      r: The registry object.
      key: String, The key of the module in the registry.
      name: String, The name of the local repository to register.
      repo: The repository object to store in the registry.

    Returns:
      Tuple, the first element is None,
      the second element is an error message in case of failure
      or None if successful.
    """
    module = r._modules.get(key)
    if module == None:
        return None, _MODULE_NOT_FOUND_ERROR.format(key = key)

    if name in module._local_repositories:
        return None, _DUPLICATE_LOCAL_REPO_ERROR.format(name = name, desc = module._description)

    module._local_repositories[name] = repo

    return None, None

def _pop_local_repo(r, *, key, name):
    """Remove the local repository from the registry and return its value.

    Fail if the repository is missing.

    Args:
      r: The registry object.
      key: String, The key of the module in the registry.
      name: String, The name of the local repository to remove.

    Returns:
      Tuple, the first element is the repository object if successful,
      the second element is an error message in case of failure
      or None if successful.
    """
    module = r._modules.get(key)
    if module == None:
        return None, _MODULE_NOT_FOUND_ERROR.format(key = key)

    if not name in module._local_repositories:
        return None, _LOCAL_REPO_NOT_FOUND_ERROR.format(name = name, desc = module._description)

    return module._local_repositories.pop(name), None

def _set_default_global_repo(r, *, name, repo):
    """Register a global repository if it has not been previously registered.

    Args:
      r: The registry object.
      name: String, The name of the global repository to register.
      repo: Any, The repository object to store in the registry.
    """
    if name not in r._global_repositories:
        r._global_repositories[name] = repo

def _has_global_repo(r, *, name):
    """Check if the global repository exists in the registry.

    Args:
      r: The registry object.
      name: String, The name of the global repository to check.

    Returns:
      Bool, True if the global repository exists, False otherwise.
    """
    return name in r._global_repositories

def _get_global_repo(r, *, name):
    """Retrieve a global repository by its name.

    Args:
      r: The registry object.
      name: String, The name of the global repository to retrieve.

    Returns:
      The repository object if found, None otherwise.
    """
    return r._global_repositories.get(name)

def _add_global_repo(r, *, name, repo):
    """Register a new global repository.

    Args:
      r: The registry object.
      name: String, The name of the global repository to register.
      repo: Any, The repository object to store in the registry.

    Returns:
      Tuple, the first element is None,
      the second element is an error message in case of failure
      or None if successful.
    """
    if name in r._global_repositories:
        return None, _DUPLICATE_GLOBAL_REPO_ERROR.format(name = name)

    r._global_repositories[name] = repo

    return None, None

def _canonical_repo_name(module_name, module_version, repo_name):
    """Generate the canonical name for a repository.

    Args:
      module_name: String, The name of the module.
      module_version: String, The version of the module.
      repo_name: String, The name of the repository.

    Returns:
      String, The canonical name of the repository.
    """
    return "{}_{}_{}".format(module_name, module_version, repo_name)

def _get_all_repositories(r):
    """Retrieve a dictionary containing all repositories.

    Args:
      r: The registry object.

    Returns:
      Dict, A dictionary containing all repositories, mapping canonical
      repository names to stored repository objects.
    """
    all_repositories = {}

    for name, repo in r._global_repositories.items():
        all_repositories[name] = repo

    for module_key, module in r._modules.items():
        for repo_name, repo in module._local_repositories.items():
            canonical_name = _canonical_repo_name(module._name, module._version, repo_name)
            all_repositories[canonical_name] = repo

    return all_repositories

def _get_all_module_scopes(r):
    """Get mapping from module keys to all repositories used by that module.

    Args:
      r: The registry object.

    Returns:
      Tuple, the first element is a mapping of module keys
      to all repositories used by that module,
      the second element is an error message in case of failure
      or None if successful.
    """
    module_scopes = {}

    for module_key, module in r._modules.items():
        repos = {}

        for repo_name in module._global_repositories:
            if not repo_name in r._global_repositories:
                return None, _GLOBAL_REPO_NOT_REGISTERED_ERROR.format(name = repo_name, desc = module._description)

            repos[repo_name] = repo_name

        for repo_name, repo in module._local_repositories.items():
            canonical_name = _canonical_repo_name(module._name, module._version, repo_name)
            repos[repo_name] = canonical_name

        module_scopes[module_key] = repos

    return module_scopes, None

_NIXPKGS_REPOSITORIES_DEFS = '''\
load("@rules_nixpkgs_core//:util.bzl", _err = "err")

{accessor}

def _get_repository(module_name, name):
    """Access a registered repository from the module registry.

    Args:
      module_name: `String`; Name of the calling Bazel module.
        This is needed until Bazel offers unique module identifiers,
        see [#17652][bazel-17652].
      name: `String`; Name of the repository.

    Returns:
      Pair of (`Label`, optional `String`)
      - `Label`; The resolved label to the repository's entry point.
      - optional `String`; `None` indicates success, otherwise an error.

    [bazel-17652]: https://github.com/bazelbuild/bazel/issues/17652
    """
    key = module_name

    if key in _MODULES and key in _MODULE_SCOPES:
        description = _MODULES[key]
        repos = _MODULE_SCOPES[key]
    else:
        return None, "Unknown module - no module found under the key '{{}}'.".format(key)

    if name in repos:
        repo_name = repos[name]
    else:
        return None, "Unknown repository - no repository named '{{}}' available for module '{{}}'.".format(name, description)

    return Label("@" + repo_name), None

_MODULES = {{
{modules}
}}
_MODULE_SCOPES = {{
{module_scopes}
}}
'''

def _format_module_scopes(module_scopes):
    return "\n".join([
        "    {}: {{\n{}\n    }},".format(repr(key), "\n".join([
            "        {}: {},".format(repr(repo_name), repr(workspace_name))
            for repo_name, workspace_name in sorted(repos.items())
        ]))
        for key, repos in sorted(module_scopes.items())
    ])

def _format_modules(modules):
    return "\n".join([
        "    {}: {},".format(repr(key), repr(desc))
        for key, desc in sorted(modules.items())
    ])

def _hub_repo_rule_impl(repository_ctx):
    module_scopes = {}

    for module_key, encoded_repos in repository_ctx.attr.module_scopes.items():
        repos = {}

        for encoded in encoded_repos:
            repo_name, workspace_name = encoded.split("~", 1)
            repos[repo_name] = workspace_name

        module_scopes[module_key] = repos

    defs = _NIXPKGS_REPOSITORIES_DEFS.format(
        accessor = repository_ctx.attr.accessor,
        modules = _format_modules(repository_ctx.attr.modules),
        module_scopes = _format_module_scopes(module_scopes),
    )
    repository_ctx.file("defs.bzl", content = defs, executable = False)
    repository_ctx.file("BUILD.bazel", content = "", executable = False)

_hub_repo_rule = repository_rule(
    _hub_repo_rule_impl,
    attrs = {
        "accessor": attr.string(),
        "modules": attr.string_dict(),
        "module_scopes": attr.string_list_dict(),
    },
)

def _hub_repo(r, *, name, accessor):
    module_scopes, err = registry.get_all_module_scopes(r)
    if err:
        return None, err

    _hub_repo_rule(
        name = name,
        accessor = accessor,
        modules = {
            key: module._description
            for key, module in r._modules.items()
        },
        module_scopes = {
            module_key: [
                "{}~{}".format(repo_name, canonical_name)
                for repo_name, canonical_name in repos.items()
            ]
            for module_key, repos in module_scopes.items()
        },
    )

    return None, None

registry = struct(
    make = _make_registry,
    add_module = _add_module,
    has_global_repo = _has_global_repo,
    get_global_repo = _get_global_repo,
    add_global_repo = _add_global_repo,
    set_default_global_repo = _set_default_global_repo,
    use_global_repo = _use_global_repo,
    add_local_repo = _add_local_repo,
    pop_local_repo = _pop_local_repo,
    get_all_repositories = _get_all_repositories,
    get_all_module_scopes = _get_all_module_scopes,
    hub_repo = _hub_repo,
)
