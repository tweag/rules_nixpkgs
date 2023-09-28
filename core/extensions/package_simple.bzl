"""Defines the nix_pkg module extension.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("//:nixpkgs.bzl", "nixpkgs_package")

# TODO[AH] Switch to @nixpkgs
_DEFAULT_NIXKGS = "@nixpkgs-simple"

_ISOLATED_OR_ROOT_ONLY_ERROR = "Illegal use of the {tag_name} tag. The {tag_name} tag may only be used on an isolated module extension or in the root module or rules_nixpkgs_core."
_DUPLICATE_PACKAGE_NAME_ERROR = "Duplicate nix_pkg import due to {tag_name} tag. The package name '{package_name}' is already used."
_ISOLATED_NOT_ALLOWED_ERROR = "Illegal use of the {tag_name} tag. The {tag_name} tag may not be used on an isolated module extension."

# TODO[AH]: Add support to configure global default Nix options.

def _get_pkg_name(attrs):
    if bool(attrs.name):
        return attrs.name
    elif bool(attrs.attr):
        return attrs.attr
    else:
        fail('The `name` attribute must be set if `attr` is the empty string `""`.')

def _handle_common_attrs(attrs):
    kwargs = {}

    kwargs["name"] = _get_pkg_name(attrs)
    kwargs["attribute_path"] = attrs.attr

    return kwargs

def _handle_repo_attrs(attrs):
    kwargs = {}

    repo_set = bool(attrs.repo)
    repos_set = bool(attrs.repos)

    if repo_set and repos_set:
        fail("Duplicate Nix repositories. Specify at most one of `repo` and `repos`.")
    elif repo_set:
        kwargs["repository"] = attrs.repo
    elif repos_set:
        kwargs["repositories"] = {
            name: repo
            for repo, names in attrs.repos.items()
            for name in names.split(":")
        }
    else:
        kwargs["repository"] = _DEFAULT_NIXKGS

    return kwargs

def _handle_build_attrs(attrs):
    kwargs = {}

    build_file_set = bool(attrs.build_file)
    build_file_content_set = bool(attrs.build_file_content)

    if build_file_set and build_file_content_set:
        fail("Duplicate BUILD file. Specify at most one of `build_file` and `build_file_contents`.")
    elif build_file_set:
        kwargs["build_file"] = attrs.build_file
    elif build_file_content_set:
        kwargs["build_file_content"] = attrs.build_file_content

    return kwargs

def _handle_file_attrs(attrs):
    kwargs = {"nix_file": attrs.file}

    if bool(attrs.file_deps):
        kwargs["nix_file_deps"] = attrs.file_deps

    return kwargs

def _handle_expr_attrs(attrs):
    kwargs = {"nix_file_content": attrs.expr}

    if bool(attrs.file_deps):
        kwargs["nix_file_deps"] = attrs.file_deps

    return kwargs

def _handle_opts_attrs(attrs):
    return {"nixopts": attrs.nixopts or []}

def _default_pkg(default):
    nixpkgs_package(
        name = default.attr,
        attribute_path = default.attr,
        repository = _DEFAULT_NIXKGS,
    )

def _attr_pkg(attr):
    kwargs = _handle_common_attrs(attr)
    kwargs.update(_handle_repo_attrs(attr))
    kwargs.update(_handle_build_attrs(attr))
    kwargs.update(_handle_opts_attrs(attr))

    nixpkgs_package(**kwargs)

def _file_pkg(file):
    kwargs = _handle_common_attrs(file)
    kwargs.update(_handle_repo_attrs(file))
    kwargs.update(_handle_build_attrs(file))
    kwargs.update(_handle_file_attrs(file))
    kwargs.update(_handle_opts_attrs(file))

    # Indicate that nixpkgs_package is called from a module extension to
    # enable required workarounds.
    # TODO[AH] Remove this once the workarounds are no longer required.
    kwargs["_bzlmod"] = True

    nixpkgs_package(**kwargs)

def _expr_pkg(expr):
    kwargs = _handle_common_attrs(expr)
    kwargs.update(_handle_repo_attrs(expr))
    kwargs.update(_handle_build_attrs(expr))
    kwargs.update(_handle_expr_attrs(expr))
    kwargs.update(_handle_opts_attrs(expr))

    nixpkgs_package(**kwargs)

_OVERRIDE_TAGS = {
    "attr": _attr_pkg,
    "file": _file_pkg,
    "expr": _expr_pkg,
}

def _nix_pkg_impl(module_ctx):
    all_pkgs = sets.make()
    root_deps = sets.make()
    root_dev_deps = sets.make()

    is_isolated = getattr(module_ctx, "is_isolated", False)

    for mod in module_ctx.modules:
        module_pkgs = sets.make()

        is_root = mod.is_root
        is_core = mod.name == "rules_nixpkgs_core"
        may_override = is_root or is_core

        for tag_name, tag_fun in _OVERRIDE_TAGS.items():
            for tag in getattr(mod.tags, tag_name):
                is_dev_dep = module_ctx.is_dev_dependency(tag)

                if not is_isolated and not may_override:
                    fail(_ISOLATED_OR_ROOT_ONLY_ERROR.format(tag_name = tag_name))

                pkg_name = _get_pkg_name(tag)

                if sets.contains(module_pkgs, pkg_name):
                    fail(_DUPLICATE_PACKAGE_NAME_ERROR.format(package_name = pkg_name, tag_name = tag_name))
                else:
                    sets.insert(module_pkgs, pkg_name)

                if is_root:
                    if is_dev_dep:
                        sets.insert(root_dev_deps, pkg_name)
                    else:
                        sets.insert(root_deps, pkg_name)

                if not sets.contains(all_pkgs, pkg_name):
                    sets.insert(all_pkgs, pkg_name)
                    tag_fun(tag)

        for default in mod.tags.default:
            if sets.contains(module_pkgs, default.attr):
                fail(_DUPLICATE_PACKAGE_NAME_ERROR.format(package_name = default.attr, tag_name = "default"))
            else:
                sets.insert(module_pkgs, default.attr)

    for mod in module_ctx.modules:
        is_root = mod.is_root

        for default in mod.tags.default:
            is_dev_dep = module_ctx.is_dev_dependency(default)

            if is_isolated:
                fail(_ISOLATED_NOT_ALLOWED_ERROR.format(tag_name = "default"))

            if not sets.contains(all_pkgs, default.attr):
                sets.insert(all_pkgs, default.attr)
                _default_pkg(default)

            if is_root:
                if is_dev_dep:
                    sets.insert(root_dev_deps, default.attr)
                else:
                    sets.insert(root_deps, default.attr)

    return module_ctx.extension_metadata(
        root_module_direct_deps = sets.to_list(root_deps),
        root_module_direct_dev_deps = sets.to_list(root_dev_deps),
    )

_DEFAULT_ATTRS = {
    "attr": attr.string(
        doc = "The attribute path of the package to import. The attribute path is a sequence of attribute names separated by dots.",
        mandatory = True,
    ),
}

_COMMON_ATTRS = {
    "attr": attr.string(
        doc = "The attribute path of the package to configure and import. The attribute path is a sequence of attribute names separated by dots.",
        mandatory = True,
    ),
    "name": attr.string(
        doc = "Configure and import the package under this name instead of the attribute path. Other modules must pass this name to the `default` tag to refer to this package.",
        mandatory = False,
    ),
}

_REPO_ATTRS = {
    "repo": attr.label(
        doc = """\
The Nix repository to use.
Equivalent to `repos = {"nixpkgs": repo}`.
Specify at most one of `repo` or `repos`.
""",
        mandatory = False,
    ),
    "repos": attr.label_keyed_string_dict(
        doc = """\
The Nix repositories to use. The dictionary values represent the names of the
`NIX_PATH` entries. For example, `repositories = { "@somerepo" : "myrepo" }`
would replace all instances of `<myrepo>` in the Nix code by the path to the
Nix repository `@somerepo`. You can provide multiple `NIX_PATH` entry names for a single repository as a colon (`:`) separated string. See the [relevant section in the nix
manual](https://nixos.org/manual/nix/stable/command-ref/env-common.html#env-NIX_PATH) for more information.
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

_FILE_DEPS_ATTRS = {
    "file_deps": attr.label_list(
        doc = "Files required by the Nix expression.",
        mandatory = False,
    ),
}

_OPTS_ATTRS = {
    "nixopts": attr.string_list(
        doc = "Extra flags to pass when calling Nix. Note, this does not currently support location expansion.",
        mandatory = False,
        # TODO[AH] Document location expansion once supported.
    ),
}

_default_tag = tag_class(
    attrs = _DEFAULT_ATTRS,
    doc = "Import a globally unified Nix package from the default nixpkgs repository. May not be used on an isolated module extension.",
)

_attr_tag = tag_class(
    attrs = dicts.add(_COMMON_ATTRS, _REPO_ATTRS, _BUILD_ATTRS, _OPTS_ATTRS),
    doc = "Configure and import a Nix package by attribute path. Overrides default imports of this package. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

_file_tag = tag_class(
    attrs = dicts.add(_COMMON_ATTRS, _REPO_ATTRS, _BUILD_ATTRS, _FILE_ATTRS, _FILE_DEPS_ATTRS, _OPTS_ATTRS),
    doc = "Configure and import a Nix package from a file. Overrides default imports of this package. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

_expr_tag = tag_class(
    attrs = dicts.add(_COMMON_ATTRS, _REPO_ATTRS, _BUILD_ATTRS, _EXPR_ATTRS, _FILE_DEPS_ATTRS, _OPTS_ATTRS),
    doc = "Configure and import a Nix package from a Nix expression. Overrides default imports of this package. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

nix_pkg = module_extension(
    _nix_pkg_impl,
    tag_classes = {
        "default": _default_tag,
        "attr": _attr_tag,
        "file": _file_tag,
        "expr": _expr_tag,
    },
)
