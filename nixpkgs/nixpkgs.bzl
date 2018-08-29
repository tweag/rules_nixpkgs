"""Rules for importing Nixpkgs packages."""

def _nixpkgs_git_repository_impl(ctx):
  ctx.file('BUILD')
  # XXX Hack because ctx.path below bails out if resolved path not a regular file.
  ctx.file(ctx.name)
  ctx.download_and_extract(
    url = "%s/archive/%s.tar.gz" % (ctx.attr.remote, ctx.attr.revision),
    stripPrefix = "nixpkgs-" + ctx.attr.revision,
    sha256 = ctx.attr.sha256,
  )

nixpkgs_git_repository = repository_rule(
  implementation = _nixpkgs_git_repository_impl,
  attrs = {
    "revision": attr.string(),
    "remote": attr.string(default = "https://github.com/NixOS/nixpkgs"),
    "sha256": attr.string(),
  },
  local = False,
)

def _nixpkgs_package_impl(ctx):
  if ctx.attr.build_file and ctx.attr.build_file_content:
    fail("Specify one of 'build_file' or 'build_file_content', but not both.")
  elif ctx.attr.build_file:
    ctx.symlink(ctx.attr.build_file, "BUILD")
  elif ctx.attr.build_file_content:
    ctx.file("BUILD", content = ctx.attr.build_file_content)
  else:
    ctx.template("BUILD", Label("@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"))

  strFailureImplicitNixpkgs = (
     "One of 'path', 'repository', 'nix_file' or 'nix_file_content' must be provided. "
     + "The NIX_PATH environment variable is not inherited.")

  expr_args = []
  if ctx.attr.nix_file and ctx.attr.nix_file_content:
    fail("Specify one of 'nix_file' or 'nix_file_content', but not both.")
  elif ctx.attr.nix_file:
    ctx.symlink(ctx.attr.nix_file, "default.nix")
  elif ctx.attr.nix_file_content:
    expr_args = ["-E", ctx.attr.nix_file_content]
  elif not (ctx.attr.path or ctx.attr.repository):
    fail(strFailureImplicitNixpkgs)
  else:
    expr_args = ["-E", "import <nixpkgs> {}"]

  # Introduce an artificial dependency with a bogus name on each of
  # the nix_file_deps.
  for dep in ctx.attr.nix_file_deps:
    components = [c for c in [dep.workspace_root, dep.package, dep.name] if c]
    link = '/'.join(components).replace('_', '_U').replace('/', '_S')
    ctx.symlink(dep, link)

  expr_args.extend([
    "-A", ctx.attr.attribute_path
          if ctx.attr.nix_file or ctx.attr.nix_file_content
          else ctx.attr.attribute_path or ctx.attr.name,
    "--no-out-link",
  ])

  # If neither repository or path are set, leave empty which will use
  # default value from NIX_PATH, which will fail unless a pinned nixpkgs is
  # set in the 'nix_file' attribute.
  nix_path = ""
  if ctx.attr.repository and ctx.attr.path:
    fail("'repository' and 'path' attributes are mutually exclusive.")
  elif ctx.attr.repository:
    # XXX Another hack: the repository label typically resolves to
    # some top-level package in the external workspace. So we use
    # dirname to get the actual workspace path.
    nix_path = str(ctx.path(ctx.attr.repository).dirname)
  elif ctx.attr.path:
    nix_path = str(ctx.attr_path)
  elif not (ctx.attr.nix_file or ctx.attr.nix_file_content):
    fail(strFailureImplicitNixpkgs)

  nix_build_path = _executable_path(
    "nix-build", ctx,
    extra_msg = "See: https://nixos.org/nix/"
  )
  nix_build = [nix_build_path] + expr_args

  # Large enough integer that Bazel can still parse. We don't have
  # access to MAX_INT and 0 is not a valid timeout so this is as good
  # as we can do.
  timeout = 1073741824

  res = ctx.execute(nix_build, quiet = False, timeout = timeout,
                    environment=dict(NIX_PATH="nixpkgs=" + nix_path))
  if res.return_code == 0:
    output_path = res.stdout.splitlines()[-1]
  else:
    _execute_error(res, "Cannot build Nix attribute `{}`"
                          .format(ctx.attr.attribute_path))

  # Build a forest of symlinks (like new_local_package() does) to the
  # Nix store.
  _symlink_children(output_path, ctx)


nixpkgs_package = repository_rule(
  implementation = _nixpkgs_package_impl,
  attrs = {
    "attribute_path": attr.string(),
    "nix_file": attr.label(allow_single_file = [".nix"]),
    "nix_file_deps": attr.label_list(),
    "nix_file_content": attr.string(),
    "path": attr.string(),
    "repository": attr.label(),
    "build_file": attr.label(),
    "build_file_content": attr.string(),
  },
  local = True,
)


def _symlink_children(target_dir, rep_ctx):
  """Create a symlink to all children of `target_dir` in the current
  build directory."""
  find_args = [
    _executable_path("find", rep_ctx),
    target_dir,
    "-maxdepth", "1",
    # otherwise the directory is printed as well
    "-mindepth", "1",
    # filenames can contain \n
    "-print0",
  ]
  find_res = rep_ctx.execute(find_args)
  if find_res.return_code == 0:
      for target in find_res.stdout.rstrip("\0").split("\0"):
        basename = target.rpartition("/")[-1]
        rep_ctx.symlink(target, basename)
  else:
    _execute_error(find_res)


def _executable_path(exe_name, rep_ctx, extra_msg=""):
  """Try to find the executable, fail with an error."""
  path = rep_ctx.which(exe_name)
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
