"""Defines the nix_repo module extension.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("//:nixpkgs.bzl", "nixpkgs_http_repository", "nixpkgs_local_repository")

_ISOLATED_OR_ROOT_ONLY_ERROR = "Illegal use of the {tag_name} tag. The {tag_name} tag may only be used on an isolated module extension or in the root module or rules_nixpkgs_core."
_ISOLATED_NOT_ALLOWED_ERROR = "Illegal use of the {tag_name} tag. The {tag_name} tag may not be used on an isolated module extension."
_DUPLICATE_REPOSITORY_NAME_ERROR = "Duplicate nix_repo import due to {tag_name} tag. The repository name '{repo_name}' is already used."
_UNKNOWN_REPOSITORY_REFERENCE_ERROR = "Reference to unknown repository '{repo_name}' encountered on {tag_name} tag."

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

    nixpkgs_http_repository(
        name = github.name,
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

    nixpkgs_http_repository(
        name = http.name,
        url = http.url if url_set else None,
        urls = http.urls if urls_set else None,
        integrity = http.integrity,
        sha256 = http.sha256,
        strip_prefix = http.strip_prefix,
    )

def _file_repo(file):
    nixpkgs_local_repository(
        name = file.name,
        nix_file = file.file,
        nix_file_deps = file.file_deps,
    )

def _expr_repo(expr):
    nixpkgs_local_repository(
        name = expr.name,
        nix_file_content = expr.expr,
        nix_file_deps = expr.file_deps,
    )

_OVERRIDE_TAGS = {
    "github": _github_repo,
    "http": _http_repo,
    "file": _file_repo,
    "expr": _expr_repo,
}

def _nix_repo_impl(module_ctx):
    all_repos = sets.make()
    root_deps = sets.make()
    root_dev_deps = sets.make()

    is_isolated = getattr(module_ctx, "is_isolated", False)

    # This loop handles all tags that can create global repository overrides,
    # or generate isolated repository instances. References to global
    # repositories are handled later.
    for mod in module_ctx.modules:
        module_repos = sets.make()

        is_root = mod.is_root
        is_core = mod.name == "rules_nixpkgs_core"
        may_override = is_root or is_core

        for tag_name, tag_fun in _OVERRIDE_TAGS.items():
            for tag in getattr(mod.tags, tag_name):
                is_dev_dep = module_ctx.is_dev_dependency(tag)

                if not is_isolated and not may_override:
                    fail(_ISOLATED_OR_ROOT_ONLY_ERROR.format(tag_name = tag_name))

                if sets.contains(module_repos, tag.name):
                    fail(_DUPLICATE_REPOSITORY_NAME_ERROR.format(repo_name = tag.name, tag_name = tag_name))
                else:
                    sets.insert(module_repos, tag.name)

                if is_root:
                    if is_dev_dep:
                        sets.insert(root_dev_deps, tag.name)
                    else:
                        sets.insert(root_deps, tag.name)

                if not sets.contains(all_repos, tag.name):
                    sets.insert(all_repos, tag.name)
                    tag_fun(tag)

        # Here we loop through the default tags only to check for duplicates.
        # The imports are performed later.
        for default in mod.tags.default:
            is_dev_dep = module_ctx.is_dev_dependency(default)

            if sets.contains(module_repos, default.name):
                if is_root and not is_dev_dep and sets.contains(root_dev_deps, default.name):
                    # Collisions between default and overrides are allowed in
                    # the root module if the override is a dev-dependency and
                    # the default is not.
                    sets.remove(root_dev_deps, default.name)
                    sets.insert(root_deps, default.name)
                else:
                    fail(_DUPLICATE_REPOSITORY_NAME_ERROR.format(repo_name = default.name, tag_name = "default"))
            else:
                sets.insert(module_repos, default.name)

    # This loop handles references to global repositories. Any instance of a
    # global override was already instantiated at this point, so we can resolve
    # references from all modules.
    for mod in module_ctx.modules:
        is_root = mod.is_root

        for default in mod.tags.default:
            is_dev_dep = module_ctx.is_dev_dependency(default)

            if is_isolated:
                fail(_ISOLATED_NOT_ALLOWED_ERROR.format(tag_name = "default"))

            if not sets.contains(all_repos, default.name):
                fail(_UNKNOWN_REPOSITORY_REFERENCE_ERROR.format(repo_name = default.name, tag_name = "default"))

            if is_root:
                if is_dev_dep:
                    sets.insert(root_dev_deps, default.name)
                else:
                    sets.insert(root_deps, default.name)

    return module_ctx.extension_metadata(
        root_module_direct_deps = sets.to_list(root_deps),
        root_module_direct_dev_deps = sets.to_list(root_dev_deps),
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

_FILE_DEPS_ATTRS = {
    "file_deps": attr.label_list(
        doc = "List of files required by the Nix expression.",
        mandatory = False,
    ),
}

_default_tag = tag_class(
    attrs = _DEFAULT_ATTRS,
    doc = "Depend on this global default repository. May not be used on an isolated module extension.",
)

_github_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _GITHUB_ATTRS, _INTEGRITY_ATTRS),
    doc = "Import a Nix repository from Github. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

_http_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _HTTP_ATTRS, _INTEGRITY_ATTRS),
    doc = "Import a Nix repository from an HTTP URL. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

_file_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _FILE_ATTRS, _FILE_DEPS_ATTRS),
    doc = "Import a Nix repository from a local file. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

_expr_tag = tag_class(
    attrs = dicts.add(_NAME_ATTRS, _EXPR_ATTRS, _FILE_DEPS_ATTRS),
    doc = "Import a Nix repository from a Nix expression. May only be used on an isolated module extension or in the root module or rules_nixpkgs_core.",
)

nix_repo = module_extension(
    _nix_repo_impl,
    tag_classes = {
        "default": _default_tag,
        "github": _github_tag,
        "http": _http_tag,
        "file": _file_tag,
        "expr": _expr_tag,
    },
)
