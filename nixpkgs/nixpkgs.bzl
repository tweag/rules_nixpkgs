"""Rules for importing Nixpkgs packages."""

def _nixpkgs_git_repository_impl(repository_ctx):
  repository_ctx.file('BUILD')
  # XXX Hack because repository_ctx.path below bails out if resolved path not a regular file.
  repository_ctx.file(repository_ctx.name)
  repository_ctx.download_and_extract(
    url = "%s/archive/%s.tar.gz" % (repository_ctx.attr.remote, repository_ctx.attr.revision),
    stripPrefix = "nixpkgs-" + repository_ctx.attr.revision,
    sha256 = repository_ctx.attr.sha256,
  )

nixpkgs_git_repository = repository_rule(
  implementation = _nixpkgs_git_repository_impl,
  attrs = {
    "revision": attr.string(mandatory = True),
    "remote": attr.string(default = "https://github.com/NixOS/nixpkgs"),
    "sha256": attr.string(),
  },
  local = False,
)

def _nixpkgs_package_impl(repository_ctx):
  repositories = None
  if repository_ctx.attr.repositories:
    repositories = repository_ctx.attr.repositories

  if repository_ctx.attr.repository:
    print("The 'repository' attribute is deprecated, use 'repositories' instead")
    repositories = { repository_ctx.attr.repository: "nixpkgs" } + \
        (repositories if repositories else {})

  if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
    fail("Specify one of 'build_file' or 'build_file_content', but not both.")
  elif repository_ctx.attr.build_file:
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD")
  elif repository_ctx.attr.build_file_content:
    repository_ctx.file("BUILD", content = repository_ctx.attr.build_file_content)
  else:
    repository_ctx.template("BUILD", Label("@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"))

  strFailureImplicitNixpkgs = (
     "One of 'repositories', 'nix_file' or 'nix_file_content' must be provided. "
     + "The NIX_PATH environment variable is not inherited.")

  expr_args = []
  if repository_ctx.attr.nix_file and repository_ctx.attr.nix_file_content:
    fail("Specify one of 'nix_file' or 'nix_file_content', but not both.")
  elif repository_ctx.attr.nix_file:
    repository_ctx.symlink(repository_ctx.attr.nix_file, "default.nix")
  elif repository_ctx.attr.nix_file_content:
    expr_args = ["-E", repository_ctx.attr.nix_file_content]
  elif not repositories:
    fail(strFailureImplicitNixpkgs)
  else:
    expr_args = ["-E", "import <nixpkgs> {}"]

  # Introduce an artificial dependency with a bogus name on each of
  # the nix_file_deps.
  for dep in repository_ctx.attr.nix_file_deps:
    components = [c for c in [dep.workspace_root, dep.package, dep.name] if c]
    link = '/'.join(components).replace('_', '_U').replace('/', '_S')
    repository_ctx.symlink(dep, link)

  expr_args.extend([
    "-A", repository_ctx.attr.attribute_path
          if repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content
          else repository_ctx.attr.attribute_path or repository_ctx.attr.name,
    # Creating an out link prevents nix from garbage collecting the store path.
    # nixpkgs uses `nix-support/` for such house-keeping files, so we mirror them
    # and use `bazel-support/`, under the assumption that no nix package has
    # a file named `bazel-support` in its root.
    # A `bazel clean` deletes the symlink and thus nix is free to garbage collect
    # the store path.
    "--out-link", "bazel-support/nix-out-link"
  ])

  # If repositories is not set, leave empty so nix will fail
  # unless a pinned nixpkgs is set in the `nix_file` attribute.
  nix_path = ""
  if repositories:
    nix_path = ":".join(
      [(path_name + "=" + str(repository_ctx.path(target)))
         for (target, path_name) in repositories.items()])
  elif not (repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content):
    fail(strFailureImplicitNixpkgs)

  nix_build_path = _executable_path(
    "nix-build", repository_ctx,
    extra_msg = "See: https://nixos.org/nix/"
  )
  nix_build = [nix_build_path] + expr_args

  # Large enough integer that Bazel can still parse. We don't have
  # access to MAX_INT and 0 is not a valid timeout so this is as good
  # as we can do.
  timeout = 1073741824

  res = repository_ctx.execute(nix_build, quiet = False, timeout = timeout,
                    environment=dict(NIX_PATH=nix_path))
  if res.return_code == 0:
    output_path = res.stdout.splitlines()[-1]
  else:
    _execute_error(res, "Cannot build Nix attribute `{}`"
                          .format(repository_ctx.attr.attribute_path))

  # Build a forest of symlinks (like new_local_package() does) to the
  # Nix store.
  _symlink_children(output_path, repository_ctx)


_nixpkgs_package = repository_rule(
  implementation = _nixpkgs_package_impl,
  attrs = {
    "attribute_path": attr.string(),
    "nix_file": attr.label(allow_single_file = [".nix"]),
    "nix_file_deps": attr.label_list(),
    "nix_file_content": attr.string(),
    "repositories": attr.label_keyed_string_dict(),
    "repository": attr.label(),
    "build_file": attr.label(),
    "build_file_content": attr.string(),
  },
  local = True,
)

def nixpkgs_package(*args, **kwargs):
  # Because of https://github.com/bazelbuild/bazel/issues/5356 we can't
  # directly pass a dict from strings to labels to the rule (which we'd like
  # for the `repositories` arguments), but we can pass a dict from labels to
  # strings. So we swap the keys and the values (assuming they all are
  # distinct).
  if "repositories" in kwargs:
    inversed_repositories = { value: key for (key, value) in kwargs["repositories"].items() }
    kwargs.pop("repositories")
    _nixpkgs_package(
      repositories = inversed_repositories,
      *args,
      **kwargs
    )
  else:
    _nixpkgs_package(*args, **kwargs)

def _symlink_children(target_dir, repository_ctx):
  """Create a symlink to all children of `target_dir` in the current
  build directory."""
  find_args = [
    _executable_path("find", repository_ctx),
    target_dir,
    "-maxdepth", "1",
    # otherwise the directory is printed as well
    "-mindepth", "1",
    # filenames can contain \n
    "-print0",
  ]
  find_res = repository_ctx.execute(find_args)
  if find_res.return_code == 0:
      for target in find_res.stdout.rstrip("\0").split("\0"):
        basename = target.rpartition("/")[-1]
        repository_ctx.symlink(target, basename)
  else:
    _execute_error(find_res)


def _executable_path(exe_name, repository_ctx, extra_msg=""):
  """Try to find the executable, fail with an error."""
  path = repository_ctx.which(exe_name)
  if path == None:
    fail("Could not find the `{}` executable in PATH.{}\n"
          .format(exe_name, " " + extra_msg if extra_msg else ""))
  return path


def _execute_error(exec_result, msg):
  """Print a nice error message for a failed `execute`."""
  fail("""
execute() error: {msg}
status code: {code}
stdout:
{stdout}
stderr:
{stderr}
""".format(
  msg=msg,
  code=exec_result.return_code,
  stdout=exec_result.stdout,
  stderr=exec_result.stderr))
