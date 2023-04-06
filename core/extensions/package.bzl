"""Defines the nix_pkg module extension.
"""

load("//:nixpkgs.bzl", "nixpkgs_package")
load("//:util.bzl", "fail_on_err")
load("//private:module_registry.bzl", "registry")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:partial.bzl", "partial")
load("@nixpkgs_repositories//:defs.bzl", "nix_repo")

_ACCESSOR = '''\
def nix_pkg(module_name, name, label):
    """Access a Nix package imported with `nix_pkg`.

    Args:
      module_name: `String`; Name of the calling Bazel module.
        This is needed until Bazel offers unique module identifiers,
        see [#17652][bazel-17652].
      name: `String`; Name of the package.
      label: `String`; Target within the package.
        A string representation of a label under the package's external
        workspace.

    Returns:
      `Label`; The resolved label to the target within the package's external workspace.

    [bazel-17652]: https://github.com/bazelbuild/bazel/issues/17652
    """
    resolved = _fail_on_err(
        _get_repository(module_name, name),
        prefix = "Invalid Nix repository, you must use the nix_repo extension and request a global repository or register a local repository: ",
    )
    return resolved.relative(label)
'''

def _name_from_attr(attr):
    """Generate a global workspace name from an attribute path.
    """
    return attr

def _attr_pkg(attr):
    return partial.make(
        nixpkgs_package,
        attribute_path = attr.attr,
        repository = nix_repo("rules_nixpkgs_core", "nixpkgs"),
    )

def _local_attr_pkg(key, local_attr):
    kwargs = {}

    if bool(local_attr.attr):
        kwargs["attribute_path"] = local_attr.attr
    else:
        kwargs["attribute_path"] = local_attr.name

    repo_set = bool(local_attr.repo)
    repos_set = bool(local_attr.repos)

    if repo_set and repos_set:
        fail("Duplicate Nix repositories. Specify at most one of `repo` and `repos`.")
    elif repo_set:
        kwargs["repository"] = nix_repo(key, local_attr.repo)
    elif repos_set:
        kwargs["repositories"] = {
            name: nix_repo(key, repo)
            for name, repo in local_attr.repos.items()
        }
    else:
        kwargs["repository"] = nix_repo(key, "nixpkgs")

    build_file_set = bool(local_attr.build_file)
    build_file_content_set = bool(local_attr.build_file_content)

    if build_file_set and build_file_content_set:
        fail("Duplicate BUILD file. Specify at most one of `build_file` and `build_file_contents`.")
    elif build_file_set:
        kwargs["build_file"] = local_attr.build_file
    elif build_file_content_set:
        kwargs["build_file"] = local_attr.build_file_content

    return partial.make(
        nixpkgs_package,
        **kwargs
    )

def _local_file_pkg(key, local_file):
    kwargs = {}

    # Inidicate that nixpkgs_package is called from a module extension to
    # enable required workarounds.
    # TODO[AH] Remove this once the workarounds are no longer required.
    kwargs["_bzlmod"] = True

    if bool(local_file.attr):
        kwargs["attribute_path"] = local_file.attr

    repo_set = bool(local_file.repo)
    repos_set = bool(local_file.repos)

    if repo_set and repos_set:
        fail("Duplicate Nix repositories. Specify at most one of `repo` and `repos`.")
    elif repo_set:
        kwargs["repository"] = nix_repo(key, local_file.repo)
    elif repos_set:
        kwargs["repositories"] = {
            name: nix_repo(key, repo)
            for name, repo in local_file.repos.items()
        }
    else:
        kwargs["repository"] = nix_repo(key, "nixpkgs")

    kwargs["nix_file"] = local_file.file
    if bool(local_file.file_deps):
        kwargs["nix_file_deps"] = local_file.file_deps

    build_file_set = bool(local_file.build_file)
    build_file_content_set = bool(local_file.build_file_content)

    if build_file_set and build_file_content_set:
        fail("Duplicate BUILD file. Specify at most one of `build_file` and `build_file_contents`.")
    elif build_file_set:
        kwargs["build_file"] = local_file.build_file
    elif build_file_content_set:
        kwargs["build_file_content"] = local_file.build_file_content

    return partial.make(
        nixpkgs_package,
        **kwargs
    )

def _local_expr_pkg(key, local_expr):
    kwargs = {}

    if bool(local_expr.attr):
        kwargs["attribute_path"] = local_expr.attr

    repo_set = bool(local_expr.repo)
    repos_set = bool(local_expr.repos)

    if repo_set and repos_set:
        fail("Duplicate Nix repositories. Specify at most one of `repo` and `repos`.")
    elif repo_set:
        kwargs["repository"] = nix_repo(key, local_expr.repo)
    elif repos_set:
        kwargs["repositories"] = {
            name: nix_repo(key, repo)
            for name, repo in local_expr.repos.items()
        }
    else:
        kwargs["repository"] = nix_repo(key, "nixpkgs")

    kwargs["nix_file_content"] = local_expr.expr
    if bool(local_expr.file_deps):
        kwargs["nix_file_deps"] = local_expr.file_deps

    build_file_set = bool(local_expr.build_file)
    build_file_content_set = bool(local_expr.build_file_content)

    if build_file_set and build_file_content_set:
        fail("Duplicate BUILD file. Specify at most one of `build_file` and `build_file_contents`.")
    elif build_file_set:
        kwargs["build_file"] = local_expr.build_file
    elif build_file_content_set:
        kwargs["build_file_content"] = local_expr.build_file_content

    return partial.make(
        nixpkgs_package,
        **kwargs
    )

def _nix_pkg_impl(module_ctx):
    r = registry.make()

    for mod in module_ctx.modules:
        key = fail_on_err(registry.add_module(r, name = mod.name, version = mod.version))

        for attr in mod.tags.attr:
            name = _name_from_attr(attr.attr)
            fail_on_err(
                registry.use_global_repo(r, key = key, name = name),
                prefix = "Cannot use unified Nix package: ",
            )
            if not registry.has_global_repo(r, name = name):
                fail_on_err(
                    registry.add_global_repo(
                        r,
                        name = name,
                        repo = _attr_pkg(attr),
                    ),
                    prefix = "Cannot define unified Nix package: ",
                )

        for local_attr in mod.tags.local_attr:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = local_attr.name,
                    repo = _local_attr_pkg(key, local_attr),
                ),
                prefix = "Cannot use Nix package: ",
            )

        for local_file in mod.tags.local_file:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = local_file.name,
                    repo = _local_file_pkg(key, local_file),
                ),
                prefix = "Cannot use Nix package: ",
            )

        for local_expr in mod.tags.local_expr:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = local_expr.name,
                    repo = _local_expr_pkg(key, local_expr),
                ),
                prefix = "Cannot use Nix package: ",
            )

    for repo_name, repo in registry.get_all_repositories(r).items():
        partial.call(repo, name = repo_name)

    fail_on_err(
        registry.hub_repo(r, name = "nixpkgs_packages", accessor = _ACCESSOR),
        prefix = "Failed to generate `nixpkgs_packages`: ",
    )

_ATTR_ATTRS = {
    "attr": attr.string(
        doc = "The attribute path of the package to import.",
        mandatory = True,
    ),
}

_COMMON_ATTRS = {
    "name": attr.string(
        doc = "A unique name for this package. The name must be unique within the requesting module.",
        mandatory = True,
    ),
    "attr": attr.string(
        doc = "The attribute path of the package to import. Defaults to `name`.",
        mandatory = False,
    ),
}

_FILE_DEPS_ATTRS = {
    "file_deps": attr.label_list(
        doc = "Files required by the Nix expression file.",
        mandatory = False,
    ),
}

_FILE_ATTRS = {
    "file": attr.label(
        doc = "The file containing the Nix expression.",
        mandatory = True,
    ),
}

_EXPR_ATTRS = {
    "expr": attr.string(
        doc = "The Nix expression.",
        mandatory = True,
    ),
}

_REPO_ATTRS = {
    "repo": attr.string(
        doc = """\
The Nix repository to use.
Equivalent to `repos = {"nixpkgs": repo}`.
Specify at most one of `repo` or `repos`.
""",
        mandatory = False,
    ),
    "repos": attr.string_dict(
        doc = """\
The Nix repositories to use. The dictionary keys represent the names of the
`NIX_PATH` entries. For example, `repositories = { "myrepo" : "somerepo" }`
would replace all instances of `<myrepo>` in the Nix code by the path to the
Nix repository `somerepo`. See the [relevant section in the nix
manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.
Specify at most one of `repo` or `repos`.
""",
        mandatory = False,
    ),
}

_BUILD_ATTRS = {
    "build_file": attr.label(
        doc = """\
The file to use as the `BUILD` file for the external workspace generated for this package.

Its contents are copied into the file `BUILD` in root of the nix output folder. The Label does not need to be named `BUILD`, but can be.

For common use cases we provide filegroups that expose certain files as targets:

<dl>
  <dt><code>:bin</code></dt>
  <dd>Everything in the <code>bin/</code> directory.</dd>
  <dt><code>:lib</code></dt>
  <dd>All <code>.so</code>, <code>.dylib</code> and <code>.a</code> files that can be found in subdirectories of <code>lib/</code>.</dd>
  <dt><code>:include</code></dt>
  <dd>All <code>.h</code>, <code>.hh</code>, <code>.hpp</code> and <code>.hxx</code> files that can be found in subdirectories of <code>include/</code>.</dd>
</dl>

If you need different files from the nix package, you can reference them like this:
```
package(default_visibility = [ "//visibility:public" ])
filegroup(
    name = "our-docs",
    srcs = glob(["share/doc/ourpackage/**/*"]),
)
```
See the bazel documentation of [`filegroup`](https://docs.bazel.build/versions/master/be/general.html#filegroup) and [`glob`](https://docs.bazel.build/versions/master/be/functions.html#glob).
Specify at most one of `build_file` or `build_file_content`.
""",
        mandatory = False,
    ),
    "build_file_content": attr.string(
        doc = """\
Like `build_file`, but a string of the contents instead of a file name.
Specify at most one of `build_file` or `build_file_content`.
""",
        mandatory = False,
    ),
}

_attr_tag = tag_class(
    attrs = _ATTR_ATTRS,
    doc = "Import a globally unified Nix package. If multiple Bazel modules import the same nixpkgs attribute, then they will all use the same external Bazel repository that imports the Nix package.",
)

_local_attr_tag = tag_class(
    attrs = dicts.add(_COMMON_ATTRS, _REPO_ATTRS, _BUILD_ATTRS),
    doc = "Import a Nix package by attribute path.",
)

_local_file_tag = tag_class(
    attrs = dicts.add(_COMMON_ATTRS, _REPO_ATTRS, _BUILD_ATTRS, _FILE_ATTRS, _FILE_DEPS_ATTRS),
    doc = "Import a Nix package from a local file.",
)

_local_expr_tag = tag_class(
    attrs = dicts.add(_COMMON_ATTRS, _REPO_ATTRS, _BUILD_ATTRS, _EXPR_ATTRS, _FILE_DEPS_ATTRS),
    doc = "Import a Nix package from a local expression.",
)

nix_pkg = module_extension(
    _nix_pkg_impl,
    tag_classes = {
        "attr": _attr_tag,
        "local_attr": _local_attr_tag,
        "local_file": _local_file_tag,
        "local_expr": _local_expr_tag,
    },
)
