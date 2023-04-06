"""Defines the nix_repo module extension.
"""

load("//:nixpkgs.bzl", "nixpkgs_http_repository", "nixpkgs_local_repository")
load("//:util.bzl", "fail_on_err")
load("//private:module_registry.bzl", "registry")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:partial.bzl", "partial")

_ACCESSOR = '''\
def nix_repo(module_name, name):
    """Access a Nix repository imported with `nix_repo`.

    Args:
      module_name: `String`; Name of the calling Bazel module.
        This is needed until Bazel offers unique module identifiers,
        see [#17652][bazel-17652].
      name: `String`; Name of the repository.

    Returns:
      The resolved label to the repository's entry point.

    [bazel-17652]: https://github.com/bazelbuild/bazel/issues/17652
    """
    resolved = _fail_on_err(
        _get_repository(module_name, name),
        prefix = "Invalid Nix repository, you must use the nix_repo extension and request a global repository or register a local repository: ",
    )
    return resolved
'''

def _github_repo(github):
    tag_set = bool(github.tag)
    commit_set = bool(github.commit)

    if tag_set and commit_set:
        fail("Duplicate Git revision. Specify only one of `tag` or `commit`.")

    if not tag_set and not commit_set:
        fail("Missing Git revision. Specify one of `tag` or `commit`.")

    if tag_set:
        archive = "refs/tags/%s.tar.gz" % github.tag
        strip_prefix = "{}-{}".format(github.repo, github.tag)
    else:
        archive = "%s.tar.gz" % github.commit
        strip_prefix = "{}-{}".format(github.repo, github.commit)

    url = "https://github.com/%s/%s/archive/%s" % (github.org, github.repo, archive)

    return partial.make(
        nixpkgs_http_repository,
        url = url,
        integrity = github.integrity,
        sha256 = github.sha256,
        strip_prefix = strip_prefix,
    )

def _http_repo(http):
    url_set = bool(http.url)
    urls_set = bool(http.urls)

    if url_set and urls_set:
        fail("Specify only one of `url` or `urls`.")

    if not url_set and not urls_set:
        fail("Missing URL. Specify one of `url` or `urls`.")

    return partial.make(
        nixpkgs_http_repository,
        url = http.url if url_set else None,
        urls = http.urls if urls_set else None,
        integrity = http.integrity,
        sha256 = http.sha256,
        strip_prefix = http.strip_prefix,
    )

def _file_repo(file):
    return partial.make(
        nixpkgs_local_repository,
        nix_file = file.file,
        nix_file_deps = file.file_deps,
    )

def _expr_repo(expr):
    return partial.make(
        nixpkgs_local_repository,
        nix_file_content = expr.expr,
        nix_file_deps = expr.file_deps,
    )

def _nix_repo_impl(module_ctx):
    r = registry.make()

    for mod in module_ctx.modules:
        key = fail_on_err(registry.add_module(r, name = mod.name, version = mod.version))

        for default in mod.tags.default:
            fail_on_err(
                registry.use_global_repo(r, key = key, name = default.name),
                prefix = "Cannot use global default repository: ",
            )

        for github in mod.tags.github:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = github.name,
                    repo = _github_repo(github),
                ),
                prefix = "Cannot import GitHub repository: ",
            )

        for http in mod.tags.http:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = http.name,
                    repo = _http_repo(http),
                ),
                prefix = "Cannot import HTTP repository: ",
            )

        for file in mod.tags.file:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = file.name,
                    repo = _file_repo(file),
                ),
                prefix = "Cannot import file repository: ",
            )

        for expr in mod.tags.expr:
            fail_on_err(
                registry.add_local_repo(
                    r,
                    key = key,
                    name = expr.name,
                    repo = _expr_repo(expr),
                ),
                prefix = "Cannot import expression repository: ",
            )

        for override in mod.tags.override:
            prefix = "Cannot override global default repository: "
            repo = fail_on_err(
                registry.pop_local_repo(r, key = key, name = override.name),
                prefix = prefix,
            )
            registry.set_default_global_repo(r, name = override.name, repo = repo)
            fail_on_err(
                registry.use_global_repo(r, key = key, name = default.name),
                prefix = prefix,
            )

    for repo_name, repo in registry.get_all_repositories(r).items():
        partial.call(repo, name = repo_name)

    fail_on_err(
        registry.hub_repo(r, name = "nixpkgs_repositories", accessor = _ACCESSOR),
        prefix = "Failed to generate `nixpkgs_repositories`: ",
    )

_DEFAULT_ATTRS = {
    "name": attr.string(
        doc = "Use this global default repository.",
        mandatory = True,
    ),
}

_NAME_ATTRS = {
    "name": attr.string(
        doc = "A unique name for this repository. The name must be unique within the requesting module.",
        mandatory = True,
    ),
}

_INTEGRITY_ATTRS = {
    "integrity": attr.string(
        doc = "Expected checksum in Subresource Integrity format of the file downloaded. This must match the checksum of the file downloaded. _It is a security risk to omit the checksum as remote files can change._ At best omitting this field will make your build non-hermetic. It is optional to make development easier but either this attribute or `sha256` should be set before shipping.",
        mandatory = False,
    ),
    "sha256": attr.string(
        doc = "The expected SHA-256 of the file downloaded. This must match the SHA-256 of the file downloaded. _It is a security risk to omit the SHA-256 as remote files can change._ At best omitting this field will make your build non-hermetic. It is optional to make development easier but either this attribute or `integrity` should be set before shipping.",
        mandatory = False,
    ),
}

_GITHUB_ATTRS = {
    "org": attr.string(
        default = "NixOS",
        doc = "The GitHub organization hosting the repository.",
        mandatory = False,
    ),
    "repo": attr.string(
        default = "nixpkgs",
        doc = "The name of the GitHub repository.",
        mandatory = False,
    ),
    "tag": attr.string(
        doc = "The Git tag to download. Specify one of `tag` or `commit`.",
        mandatory = False,
    ),
    "commit": attr.string(
        doc = "The Git commit to download. Specify one of `tag` or `commit`.",
        mandatory = False,
    ),
}

_HTTP_ATTRS = {
    "url": attr.string(
        doc = "URL to download from. Specify one of `url` or `urls`.",
        mandatory = False,
    ),
    "urls": attr.string_list(
        doc = "List of URLs to download from. Specify one of `url` or `urls`.",
        mandatory = False,
    ),
    "strip_prefix": attr.string(
        doc = "A directory prefix to strip from the extracted files.",
        mandatory = False,
    ),
}

_FILE_DEPS_ATTRS = {
    "file_deps": attr.label_list(
        doc = "List of files required by the Nix expression.",
        mandatory = False,
    ),
}

_FILE_ATTRS = {
    "file": attr.label(
        doc = "The file containing the Nix expression.",
        mandatory = True,
        allow_single_file = True,
    ),
}

_EXPR_ATTRS = {
    "expr": attr.string(
        doc = "The Nix expression.",
        mandatory = True,
    ),
}

_OVERRIDE_ATTRS = {
    "name": attr.string(
        doc = "The name of the global default repository to set.",
        mandatory = True,
    ),
}

_default_tag = tag_class(
    attrs = _DEFAULT_ATTRS,
    doc = "Depend on this global default repository.",
)

_github_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _GITHUB_ATTRS, _INTEGRITY_ATTRS),
    doc = "Import a Nix repository from Github.",
)

_http_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _HTTP_ATTRS, _INTEGRITY_ATTRS),
    doc = "Import a Nix repository from an HTTP URL.",
)

_file_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _FILE_ATTRS, _FILE_DEPS_ATTRS),
    doc = "Import a Nix repository from a local file.",
)

_expr_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _EXPR_ATTRS, _FILE_DEPS_ATTRS),
    doc = "Import a Nix repository from a Nix expression.",
)

_override_tag = tag_class(
    attrs = _OVERRIDE_ATTRS,
    doc = "Define the global default Nix repository. May only be used in the root module or rules_nixpkgs_core.",
)

nix_repo = module_extension(
    _nix_repo_impl,
    tag_classes = {
        "default": _default_tag,
        "github": _github_tag,
        "http": _http_tag,
        "file": _file_tag,
        "expr": _expr_tag,
        "override": _override_tag,
    },
)
