"""<!-- Edit the docstring in `core/nixpkgs.bzl` and run `bazel run @rules_nixpkgs_docs//:update-readme` to change this repository's `README.md`. -->

# Nixpkgs rules for Bazel

[![Continuous integration](https://github.com/tweag/rules_nixpkgs/actions/workflows/workflow.yaml/badge.svg)](https://github.com/tweag/rules_nixpkgs/actions/workflows/workflow.yaml)

Use [Nix][nix] and the [Nixpkgs][nixpkgs] package set to import
external dependencies (like system packages) into [Bazel][bazel]
hermetically. If the version of any dependency changes, Bazel will
correctly rebuild targets, and only those targets that use the
external dependencies that changed.

Links:
* [Nix + Bazel = fully reproducible, incremental
  builds][blog-bazel-nix] (blog post)
* [Nix + Bazel][youtube-bazel-nix] (lightning talk)

[nix]: https://nixos.org/nix
[nixpkgs]: https://github.com/NixOS/nixpkgs
[bazel]: https://bazel.build
[blog-bazel-nix]: https://www.tweag.io/posts/2018-03-15-bazel-nix.html
[youtube-bazel-nix]: https://www.youtube.com/watch?v=7-K_RmDasEg&t=2030s

See [examples](/examples/toolchains) for how to use `rules_nixpkgs` with different toolchains.

## Rules

* [nixpkgs_git_repository](#nixpkgs_git_repository)
* [nixpkgs_http_repository](#nixpkgs_http_repository)
* [nixpkgs_local_repository](#nixpkgs_local_repository)
* [nixpkgs_package](#nixpkgs_package)
* [nixpkgs_flake_package](#nixpkgs_flake_package)
"""

load(
    ":util.bzl",
    "cp",
    "executable_path",
    "execute_or_fail",
    "expand_location",
    "external_repository_root",
    "find_children",
    "is_supported_platform",
)

def _nixpkgs_http_repository_impl(repository_ctx):
    url_set = bool(repository_ctx.attr.url)
    urls_set = bool(repository_ctx.attr.urls)

    if url_set and urls_set:
        fail("Duplicate URL attributes, specify only one of 'url' or 'urls'.")

    if not url_set and not urls_set:
        fail("Missing URL, specify one of 'url' or 'urls'.")

    if url_set:
        url = repository_ctx.attr.url
    else:
        url = repository_ctx.attr.urls

    integrity_set = bool(repository_ctx.attr.integrity)
    sha256_set = bool(repository_ctx.attr.sha256)

    if integrity_set and sha256_set:
        fail("Duplicate integrity attributes, specify only one of 'integrity' or 'sha256'.")

    repository_ctx.file(
        "BUILD",
        content = 'filegroup(name = "srcs", srcs = glob(["**"]), visibility = ["//visibility:public"])',
    )

    # Make "@nixpkgs" (syntactic sugar for "@nixpkgs//:nixpkgs") a valid
    # label for default.nix.
    repository_ctx.symlink("default.nix", repository_ctx.attr.unmangled_name)

    # TODO return sha256/integrity result for reproducibility warning.
    repository_ctx.download_and_extract(
        url = url,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
        auth = repository_ctx.attr.auth,
        integrity = repository_ctx.attr.integrity,
    )

_nixpkgs_http_repository = repository_rule(
    implementation = _nixpkgs_http_repository_impl,
    attrs = {
        # The workspace name as specified by the user. Needed for bzlmod
        # compatibility, as other means of retrieving the name only return the
        # mangled name, not the user defined name.
        "unmangled_name": attr.string(mandatory = True),
        "url": attr.string(),
        "urls": attr.string_list(),
        "auth": attr.string_dict(),
        "strip_prefix": attr.string(),
        "integrity": attr.string(),
        "sha256": attr.string(),
    },
)

def nixpkgs_http_repository(
        *,
        name,
        url = None,
        urls = None,
        auth = None,
        strip_prefix = None,
        integrity = None,
        sha256 = None,
        **kwargs):
    """Download a Nixpkgs repository over HTTP.

    Args:
      name: String

        A unique name for this repository.

      url: String

        A URL to download the repository from.

        This must be a file, http or https URL. Redirections are followed.

        More flexibility can be achieved by the urls parameter that allows
        to specify alternative URLs to fetch from.

      urls: List of String

        A list of URLs to download the repository from.

        Each entry must be a file, http or https URL. Redirections are followed.

        URLs are tried in order until one succeeds, so you should list local mirrors first.
        If all downloads fail, the rule will fail.

      auth: Dict of String

        An optional dict mapping host names to custom authorization patterns.

        If a URL's host name is present in this dict the value will be used as a pattern when
        generating the authorization header for the http request. This enables the use of custom
        authorization schemes used in a lot of common cloud storage providers.

        The pattern currently supports 2 tokens: <code>&lt;login&gt;</code> and
        <code>&lt;password&gt;</code>, which are replaced with their equivalent value
        in the netrc file for the same host name. After formatting, the result is set
        as the value for the <code>Authorization</code> field of the HTTP request.

        Example attribute and netrc for a http download to an oauth2 enabled API using a bearer token:

        <pre>
        auth_patterns = {
            "storage.cloudprovider.com": "Bearer &lt;password&gt;"
        }
        </pre>

        netrc:

        <pre>
        machine storage.cloudprovider.com
                password RANDOM-TOKEN
        </pre>

        The final HTTP request would have the following header:

        <pre>
        Authorization: Bearer RANDOM-TOKEN
        </pre>

      strip_prefix: String

        A directory prefix to strip from the extracted files.

        Many archives contain a top-level directory that contains all of the useful
        files in archive. This field can be used to strip it from all of the
        extracted files.

        For example, suppose you are using `nixpkgs-22.11.zip`, which contains
        the directory `nixpkgs-22.11/` under which there is the `default.nix`
        file and the `pkgs/` directory. Specify `strip_prefix =
        "nixpkgs-22.11"` to use the `nixpkgs-22.11` directory as your top-level
        directory.

        Note that if there are files outside of this directory, they will be
        discarded and inaccessible (e.g., a top-level license file). This includes
        files/directories that start with the prefix but are not in the directory
        (e.g., `nixpkgs-22.11.release-notes`). If the specified prefix does not
        match a directory in the archive, Bazel will return an error.

      integrity: String

        Expected checksum in Subresource Integrity format of the file downloaded.

        This must match the checksum of the file downloaded. _It is a security risk
        to omit the checksum as remote files can change._ At best omitting this
        field will make your build non-hermetic. It is optional to make development
        easier but either this attribute or `sha256` should be set before shipping.

      sha256: String
        The expected SHA-256 of the file downloaded.

        This must match the SHA-256 of the file downloaded. _It is a security risk
        to omit the SHA-256 as remote files can change._ At best omitting this
        field will make your build non-hermetic. It is optional to make development
        easier but should be set before shipping.

      **kwargs: Additional arguments to forward to the underlying repository rule.
    """
    if url != None:
        kwargs["url"] = url

    if urls != None:
        kwargs["urls"] = urls

    if auth != None:
        kwargs["auth"] = auth

    if strip_prefix != None:
        kwargs["strip_prefix"] = strip_prefix

    if integrity != None:
        kwargs["integrity"] = integrity

    if sha256 != None:
        kwargs["sha256"] = sha256

    _nixpkgs_http_repository(
        name = name,
        unmangled_name = name,
        **kwargs
    )

def nixpkgs_git_repository(
        *,
        name,
        revision,
        remote = "https://github.com/NixOS/nixpkgs",
        sha256 = None,
        **kwargs):
    """Name a specific revision of Nixpkgs on GitHub or a local checkout.

    Args:
      name: String

        A unique name for this repository.
      revision: String

        Git commit hash or tag identifying the version of Nixpkgs to use.
      remote: String

        The URI of the remote Git repository. This must be a HTTP URL. There is
        currently no support for authentication. Defaults to [upstream
        nixpkgs](https://github.com/NixOS/nixpkgs).
      sha256: String

        The SHA256 used to verify the integrity of the repository.
      **kwargs: Additional arguments to forward to the underlying repository rule.
    """
    _nixpkgs_http_repository(
        name = name,
        unmangled_name = name,
        url = "https://github.com/NixOS/nixpkgs/archive/%s.tar.gz" % revision,
        sha256 = sha256,
        strip_prefix = "nixpkgs-%s" % revision,
        **kwargs
    )

def _nixpkgs_local_repository_impl(repository_ctx):
    if bool(repository_ctx.attr.nix_file) and bool(repository_ctx.attr.nix_file_content) or \
       bool(repository_ctx.attr.nix_file) and bool(repository_ctx.attr.nix_flake_lock_file) or \
       bool(repository_ctx.attr.nix_flake_lock_file) and bool(repository_ctx.attr.nix_file_content):
        fail("Specify only one of 'nix_file', 'nix_file_content' or 'nix_flake_lock_file'.")

    if repository_ctx.attr.nix_file_content:
        target = "default.nix"
        repository_ctx.file(
            target,
            content = repository_ctx.attr.nix_file_content,
            executable = False,
        )
    elif repository_ctx.attr.nix_file:
        target = cp(repository_ctx, repository_ctx.attr.nix_file)
    elif repository_ctx.attr.nix_flake_lock_file:
        lock_filename = cp(repository_ctx, repository_ctx.attr.nix_flake_lock_file)
        target = "nixpkgs.nix"
        repository_ctx.file(
            target,
            content = """
let
  lock = builtins.fromJSON (builtins.readFile ./{});
  src = lock.nodes.nixpkgs.locked;
  nixpkgs =
    assert src.type == "github";
    fetchTarball {{
      url = "https://github.com/${{src.owner}}/${{src.repo}}/archive/${{src.rev}}.tar.gz";
      sha256 = src.narHash;
    }};
in
import nixpkgs
            """.format(lock_filename),
            executable = False,
        )
    else:
        fail("Specify at least one of 'nix_file', 'nix_file_content' or 'nix_flake_lock_file'.")

    repository_files = [target]
    for dep in repository_ctx.attr.nix_file_deps:
        dest = cp(repository_ctx, dep)
        repository_files.append(dest)

    # Export all specified Nix files to make them dependencies of a
    # nixpkgs_package rule.
    export_files = "exports_files({})".format(repository_files)
    repository_ctx.file("BUILD", content = export_files)

    # Create a file listing all Nix files of this repository. This
    # file is used by the nixpgks_package rule to register all Nix
    # files.
    repository_ctx.file("nix-file-deps", content = "\n".join(repository_files))

    # Make "@nixpkgs" (syntactic sugar for "@nixpkgs//:nixpkgs") a valid
    # label for the target Nix file.
    # produces _main~non_module_deps~nixpkgs_content
    repository_ctx.symlink(target, repository_ctx.attr.unmangled_name)

_nixpkgs_local_repository = repository_rule(
    implementation = _nixpkgs_local_repository_impl,
    attrs = {
        # The workspace name as specified by the user. Needed for bzlmod
        # compatibility, as other means of retrieving the name only return the
        # mangled name, not the user defined name.
        "unmangled_name": attr.string(mandatory = True),
        "nix_file": attr.label(allow_single_file = [".nix"]),
        "nix_file_deps": attr.label_list(),
        "nix_file_content": attr.string(),
        "nix_flake_lock_file": attr.label(allow_single_file = [".lock"]),
    },
)

def nixpkgs_local_repository(
        *,
        name,
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nix_flake_lock_file = None,
        **kwargs):
    """Create an external repository representing the content of Nixpkgs.

    Based on a Nix expression stored locally or provided inline. One of
    `nix_file` or `nix_file_content` must be provided.

    Args:
      name: String

        A unique name for this repository.
      nix_file: Label

        A file containing an expression for a Nix derivation.
      nix_file_deps: List of labels

        Dependencies of `nix_file` if any.
      nix_file_content: String

        An expression for a Nix derivation.
      nix_flake_lock_file: String

        A flake lock file that can be used on the provided nixpkgs repository.
      **kwargs: Additional arguments to forward to the underlying repository rule.
    """
    _nixpkgs_local_repository(
        name = name,
        unmangled_name = name,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        nix_flake_lock_file = nix_flake_lock_file,
        **kwargs
    )

def _nixpkgs_build_file_content(repository_ctx):
    # Workaround to bazelbuild/bazel#4533
    repository_ctx.path("BUILD")
    repository_ctx.path("BUILD.bazel")

    if repository_ctx.attr.build_file:
        repository_ctx.path(repository_ctx.attr.build_file)

    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Specify one of 'build_file' or 'build_file_content', but not both.")

    if repository_ctx.attr.build_file:
        return repository_ctx.read(repository_ctx.attr.build_file)
    elif repository_ctx.attr.build_file_content:
        return repository_ctx.attr.build_file_content
    else:
        return None

def _nixpkgs_build_and_symlink(repository_ctx, nix_build_cmd, expr_args, build_file_content):
    # Large enough integer that Bazel can still parse. We don't have
    # access to MAX_INT and 0 is not a valid timeout so this is as good
    # as we can do. The value shouldn't be too large to avoid errors on
    # macOS, see https://github.com/tweag/rules_nixpkgs/issues/92.
    timeout = 8640000
    repository_ctx.report_progress("Building Nix derivation")

    nix_path = executable_path(
        repository_ctx,
        "nix",
        extra_msg = "See: https://nixos.org/nix/",
    )

    nix_host = repository_ctx.os.environ.get('BAZEL_NIX_REMOTE', '')
    if nix_host:
        nix_store = "ssh-ng://{host}?max-connections=1".format(host = nix_host)
        repository_ctx.report_progress("Remote-building Nix derivation")
        exec_result = execute_or_fail(
             repository_ctx,
             nix_build_cmd + ["--store", nix_store, "--eval-store", "auto"] + expr_args,
             failure_message = "Cannot build Nix attribute '{}'.".format(
                 repository_ctx.attr.name,
             ),
             quiet = repository_ctx.attr.quiet,
             timeout = timeout,
        )
        output_path = exec_result.stdout.splitlines()[-1]

        ssh_path = repository_ctx.which("ssh")
        repository_ctx.report_progress("Creating remote store root")
        exec_result = execute_or_fail(
            repository_ctx,
            [ssh_path] + [nix_host, "nix-store --add-root ~/rules_nixpkgs_gcroots/{root} -r {path}".format(root = output_path.split('/')[-1], path = output_path) ],
            failure_message = "Cannot create remote store root for Nix attribute '{}'.".format(
                repository_ctx.attr.name,
            ),
            quiet = repository_ctx.attr.quiet,
            timeout = 10000,
        )

        repository_ctx.report_progress("Downloading Nix derivation")
        exec_result = repository_ctx.execute(
            [nix_path, "copy", "--from", nix_store, output_path],
            quiet = repository_ctx.attr.quiet,
            timeout = 10000,
        )

    exec_result = execute_or_fail(
        repository_ctx,
        nix_build_cmd + expr_args,
        failure_message = "Cannot build Nix derivation for package '@{}'.".format(repository_ctx.name),
        quiet = repository_ctx.attr.quiet,
        timeout = timeout,
    )
    output_path = exec_result.stdout.splitlines()[-1]

    repository_ctx.report_progress("Creating local folders")

    # ensure that the output is a directory
    test_path = repository_ctx.which("test")
    execute_or_fail(
        repository_ctx,
        [test_path, "-d", output_path],
        failure_message = "Package '@{}' outputs a single file which is not supported by rules_nixpkgs. Please only use directories.".format(
            repository_ctx.name,
        ),
    )

    # Build a forest of symlinks (like new_local_package() does) to the
    # Nix store.
    for target in find_children(repository_ctx, output_path):
        basename = target.rpartition("/")[-1]
        repository_ctx.symlink(target, basename)

    # Create a default BUILD file only if it does not exists and is not
    # provided by `build_file` or `build_file_content`.
    if not repository_ctx.path("BUILD").exists and not repository_ctx.path("BUILD.bazel").exists:
        if build_file_content:
            repository_ctx.file("BUILD", content = build_file_content)
        else:
            repository_ctx.template("BUILD", Label("@rules_nixpkgs_core//:BUILD.bazel.tpl"))
    elif build_file_content:
        fail("One of 'build_file' or 'build_file_content' was specified but Nix derivation already contains 'BUILD' or 'BUILD.bazel'.")

def _nixpkgs_package_impl(repository_ctx):
    repository = repository_ctx.attr.repository
    repositories = repository_ctx.attr.repositories

    expr_args = []

    strFailureImplicitNixpkgs = (
        "One of 'repositories', 'nix_file' or 'nix_file_content' must be provided. " +
        "The NIX_PATH environment variable is not inherited."
    )

    if repository and repositories or not repository and not repositories:
        fail("Specify one of 'repository' or 'repositories' (but not both).")
    elif repository:
        repositories = {repository_ctx.attr.repository: "nixpkgs"}

    for repo in repositories.keys():
        path = str(repository_ctx.path(repo).dirname) + "/nix-file-deps"
        if repository_ctx.path(path).exists:
            content = repository_ctx.read(path)
            for f in content.splitlines():
                # Hack: this is to register all Nix files as dependencies
                # of this rule (see issue #113)
                repository_ctx.path(repo.relative(":{}".format(f)))

    # If repositories is not set, leave empty so nix will fail
    # unless a pinned nixpkgs is set in the `nix_file` attribute.
    nix_path = [
        "{}={}".format(prefix, repository_ctx.path(repo))
        for (repo, prefix) in repositories.items()
    ]
    if not (repositories or repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content):
        fail(strFailureImplicitNixpkgs)

    for dir in nix_path:
        expr_args.extend(["-I", dir])

    # Workaround to bazelbuild/bazel#4533 -- to prevent this rule being restarted after running cp,
    # resolve all dependencies of this rule before running cp
    #
    # Remove the following repository_ctx.path() once bazelbuild/bazel#4533 is resolved.
    build_file_content = _nixpkgs_build_file_content(repository_ctx)

    if repository_ctx.attr.nix_file:
        repository_ctx.path(repository_ctx.attr.nix_file)
        repository_ctx.path(external_repository_root(repository_ctx.attr.nix_file))

    for dep in repository_ctx.attr.nix_file_deps:
        repository_ctx.path(dep)
        repository_ctx.path(external_repository_root(dep))

    # Is nix supported on this platform?
    not_supported = not is_supported_platform(repository_ctx)

    # Should we fail if Nix is not supported?
    fail_not_supported = repository_ctx.attr.fail_not_supported

    if not_supported and fail_not_supported:
        fail("Platform is not supported: nix-build not found in PATH. See attribute fail_not_supported if you don't want to use Nix.")
    elif not_supported:
        return

    if repository_ctx.attr.nix_file and repository_ctx.attr.nix_file_content:
        fail("Specify one of 'nix_file' or 'nix_file_content', but not both.")
    elif repository_ctx.attr.nix_file:
        nix_file = cp(repository_ctx, repository_ctx.attr.nix_file)
        expr_args.append(repository_ctx.path(nix_file))
    elif repository_ctx.attr.nix_file_content:
        expr_args.extend(["-E", repository_ctx.attr.nix_file_content])
    else:
        expr_args.extend(["-E", "import <nixpkgs> { config = {}; overlays = []; }"])

    nix_file_deps = {}
    for dep_lbl, dep_str in repository_ctx.attr.nix_file_deps.items():
        nix_file_deps[dep_str] = cp(repository_ctx, dep_lbl)

    expr_args.extend([
        "-A",
        repository_ctx.attr.attribute_path if repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content else repository_ctx.attr.attribute_path or repository_ctx.attr.unmangled_name,
        # Creating an out link prevents nix from garbage collecting the store path.
        # nixpkgs uses `nix-support/` for such house-keeping files, so we mirror them
        # and use `bazel-support/`, under the assumption that no nix package has
        # a file named `bazel-support` in its root.
        # A `bazel clean` deletes the symlink and thus nix is free to garbage collect
        # the store path.
        "--out-link",
        "bazel-support/nix-out-link",
    ])

    expr_args.extend([
        expand_location(
            repository_ctx = repository_ctx,
            string = opt,
            labels = nix_file_deps,
            attr = "nixopts",
        )
        for opt in repository_ctx.attr.nixopts
    ])

    nix_build_path = executable_path(
        repository_ctx,
        "nix-build",
        extra_msg = "See: https://nixos.org/nix/",
    )

    _nixpkgs_build_and_symlink(repository_ctx, [nix_build_path], expr_args, build_file_content)

_nixpkgs_package = repository_rule(
    implementation = _nixpkgs_package_impl,
    attrs = {
        # The workspace name as specified by the user. Needed for bzlmod
        # compatibility, as other means of retrieving the name only return the
        # mangled name, not the user defined name.
        "unmangled_name": attr.string(mandatory = True),
        "attribute_path": attr.string(),
        "nix_file": attr.label(allow_single_file = [".nix"]),
        "nix_file_deps": attr.label_keyed_string_dict(),
        "nix_file_content": attr.string(),
        "repositories": attr.label_keyed_string_dict(),
        "repository": attr.label(),
        "build_file": attr.label(),
        "build_file_content": attr.string(),
        "nixopts": attr.string_list(),
        "quiet": attr.bool(),
        "fail_not_supported": attr.bool(default = True, doc = """
            If set to True (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to False calling this rule will succeed but no output will be generated.
                                        """),
    },
)

def nixpkgs_package(
        name,
        attribute_path = "",
        nix_file = None,
        nix_file_deps = [],
        nix_file_content = "",
        repository = None,
        repositories = {},
        build_file = None,
        build_file_content = "",
        nixopts = [],
        quiet = False,
        fail_not_supported = True,
        **kwargs):
    """Make the content of a Nixpkgs package available in the Bazel workspace.

    If `repositories` is not specified, you must provide a nixpkgs clone in `nix_file` or `nix_file_content`.

    Args:
      name: A unique name for this repository.
      attribute_path: Select an attribute from the top-level Nix expression being evaluated. The attribute path is a sequence of attribute names separated by dots.
      nix_file: A file containing an expression for a Nix derivation.
      nix_file_deps: Dependencies of `nix_file` if any.
      nix_file_content: An expression for a Nix derivation.
      repository: A repository label identifying which Nixpkgs to use. Equivalent to `repositories = { "nixpkgs": ...}`
      repositories: A dictionary mapping `NIX_PATH` entries to repository labels.

        Setting it to
        ```
        repositories = { "myrepo" : "//:myrepo" }
        ```
        for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.

        Specify one of `repository` or `repositories`.
      build_file: The file to use as the BUILD file for this repository.

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
      build_file_content: Like `build_file`, but a string of the contents instead of a file name.
      nixopts: Extra flags to pass when calling Nix.

        Subject to location expansion, any instance of `$(location LABEL)` will be replaced by the path to the file referenced by `LABEL` relative to the workspace root.

        Note, labels to external workspaces will resolve to paths that contain `~` characters if the Bazel flag `--enable_bzlmod` is true. Nix does not support `~` characters in path literals at the time of writing, see [#7742](https://github.com/NixOS/nix/issues/7742). Meaning, the result of location expansion may not form a valid Nix path literal. Use `./$${"$(location @for//:example)"}` to work around this limitation if you need to pass a path argument via `--arg`, or pass the resulting path as a string value using `--argstr` and combine it with an additional `--arg workspace_root ./.` argument using `workspace_root + ("/" + path_str)`.
      quiet: Whether to hide the output of the Nix command.
      fail_not_supported: If set to `True` (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to `False` calling this rule will succeed but no output will be generated.
    """
    if kwargs.pop("_bzlmod", None):
        # The workaround to map canonicalized labels to the user provided
        # string representation to enable location expansion does not work when
        # nixpkgs_package is invoked from a module extension, because module
        # extension tags cannot be wrapped in macros.
        # Until we find a solution to this issue, we provide the canonicalized
        # label as a string. Location expansion will have to be performed on
        # canonicalized labels until a better solution is found.
        # TODO[AH] Support proper location expansion in module extension.
        nix_file_deps = {dep: str(dep) for dep in nix_file_deps} if nix_file_deps else {}
    else:
        nix_file_deps = {dep: dep for dep in nix_file_deps} if nix_file_deps else {}
    kwargs.update(
        name = name,
        unmangled_name = name,
        attribute_path = attribute_path,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        repository = repository,
        repositories = repositories,
        build_file = build_file,
        build_file_content = build_file_content,
        nixopts = nixopts,
        quiet = quiet,
        fail_not_supported = fail_not_supported,
    )

    # Because of https://github.com/bazelbuild/bazel/issues/7989 we can't
    # directly pass a dict from strings to labels to the rule (which we'd like
    # for the `repositories` arguments), but we can pass a dict from labels to
    # strings. So we swap the keys and the values (assuming they all are
    # distinct).
    if "repositories" in kwargs:
        inversed_repositories = {value: key for (key, value) in kwargs["repositories"].items()}
        kwargs["repositories"] = inversed_repositories

    _nixpkgs_package(**kwargs)

def _nixpkgs_flake_package_impl(repository_ctx):
    # Workaround to bazelbuild/bazel#4533 -- to prevent this rule being restarted after running cp,
    # resolve all dependencies of this rule before running cp
    #
    # Remove the following repository_ctx.path() once bazelbuild/bazel#4533 is resolved.
    build_file_content = _nixpkgs_build_file_content(repository_ctx)

    repository_ctx.path(repository_ctx.attr.nix_flake_file)
    repository_ctx.path(external_repository_root(repository_ctx.attr.nix_flake_file))
    repository_ctx.path(repository_ctx.attr.nix_flake_lock_file)
    repository_ctx.path(external_repository_root(repository_ctx.attr.nix_flake_lock_file))

    for dep in repository_ctx.attr.nix_flake_file_deps:
        repository_ctx.path(dep)
        repository_ctx.path(external_repository_root(dep))

    # Is nix supported on this platform?
    not_supported = not is_supported_platform(repository_ctx)

    # Should we fail if Nix is not supported?
    fail_not_supported = repository_ctx.attr.fail_not_supported

    if not_supported and fail_not_supported:
        fail("Platform is not supported: `nix` not found in PATH. See attribute `fail_not_supported` if you don't want to use Nix.")
    elif not_supported:
        return

    nix_flake_file_deps = {}
    for dep_lbl, dep_str in repository_ctx.attr.nix_flake_file_deps.items():
        nix_flake_file_deps[dep_str] = cp(repository_ctx, dep_lbl)

    nix_build_target = str(repository_ctx.path(repository_ctx.attr.nix_flake_file).dirname)
    if repository_ctx.attr.package:
        nix_build_target += "#" + repository_ctx.attr.package

    expr_args = [nix_build_target]

    # `nix build` doesn't print the output path by default.
    expr_args.extend(["--print-out-paths"])

    expr_args.extend([
        # Creating an out link prevents nix from garbage collecting the store path.
        # nixpkgs uses `nix-support/` for such house-keeping files, so we mirror them
        # and use `bazel-support/`, under the assumption that no nix package has
        # a file named `bazel-support` in its root.
        # A `bazel clean` deletes the symlink and thus nix is free to garbage collect
        # the store path.
        "--out-link",
        "bazel-support/nix-out-link",
    ])

    expr_args.extend([
        expand_location(
            repository_ctx = repository_ctx,
            string = opt,
            labels = nix_flake_file_deps,
            attr = "nixopts",
        )
        for opt in repository_ctx.attr.nixopts
    ])

    nix_path = executable_path(
        repository_ctx,
        "nix",
        extra_msg = "See: https://nixos.org/nix/",
    )

    _nixpkgs_build_and_symlink(repository_ctx, [nix_path, "build"], expr_args, build_file_content)

_nixpkgs_flake_package = repository_rule(
    implementation = _nixpkgs_flake_package_impl,
    attrs = {
        "nix_flake_file": attr.label(mandatory = True, allow_single_file = ["flake.nix"]),
        "nix_flake_lock_file": attr.label(mandatory = True, allow_single_file = ["flake.lock"]),
        "nix_flake_file_deps": attr.label_keyed_string_dict(),
        "package": attr.string(doc = "Defaults to `default`"),
        "build_file": attr.label(),
        "build_file_content": attr.string(),
        "nixopts": attr.string_list(),
        "quiet": attr.bool(),
        "fail_not_supported": attr.bool(default = True, doc = """
            If set to True (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to False calling this rule will succeed but no output will be generated.
                                        """),
    },
)

def nixpkgs_flake_package(
        name,
        nix_flake_file,
        nix_flake_lock_file,
        nix_flake_file_deps = [],
        package = None,
        build_file = None,
        build_file_content = "",
        nixopts = [],
        quiet = False,
        fail_not_supported = True,
        **kwargs):
    """Make the content of a local Nix Flake package available in the Bazel workspace.

    Args:
      name: A unique name for this repository.
      nix_flake_file: Label to `flake.nix` that will be evaluated.
      nix_flake_lock_file: Label to `flake.lock` that corresponds to `nix_flake_file`.
      nix_flake_file_deps: Additional dependencies of `nix_flake_file` if any.
      package: Nix Flake package to make available.  The default package will be used if not specified.
      build_file: The file to use as the BUILD file for this repository. See [`nixpkgs_package`](#nixpkgs_package-build_file) for more information.
      build_file_content: Like `build_file`, but a string of the contents instead of a file name. See [`nixpkgs_package`](#nixpkgs_package-build_file_content) for more information.
      nixopts: Extra flags to pass when calling Nix. See [`nixpkgs_package`](#nixpkgs_package-nixopts) for more information.
      quiet: Whether to hide the output of the Nix command.
      fail_not_supported: If set to `True` (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to `False` calling this rule will succeed but no output will be generated.
    """
    if kwargs.pop("_bzlmod", None):
        # The workaround to map canonicalized labels to the user provided
        # string representation to enable location expansion does not work when
        # nixpkgs_package is invoked from a module extension, because module
        # extension tags cannot be wrapped in macros.
        # Until we find a solution to this issue, we provide the canonicalized
        # label as a string. Location expansion will have to be performed on
        # canonicalized labels until a better solution is found.
        # TODO[AH] Support proper location expansion in module extension.
        nix_flake_file_deps = {dep: str(dep) for dep in nix_flake_file_deps} if nix_flake_file_deps else {}
    else:
        nix_flake_file_deps = {dep: dep for dep in nix_flake_file_deps} if nix_flake_file_deps else {}
    kwargs.update(
        name = name,
        nix_flake_file = nix_flake_file,
        nix_flake_lock_file = nix_flake_lock_file,
        nix_flake_file_deps = nix_flake_file_deps,
        package = package,
        build_file = build_file,
        build_file_content = build_file_content,
        nixopts = nixopts,
        quiet = quiet,
        fail_not_supported = fail_not_supported,
    )

    _nixpkgs_flake_package(**kwargs)
