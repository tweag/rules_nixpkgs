load("@bazel_tools//tools/cpp:cc_configure.bzl", "cc_autoconf_impl")

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

  expr_args = []
  if ctx.attr.nix_file and ctx.attr.nix_file_content:
    fail("Specify one of 'nix_file' or 'nix_file_content', but not both.")
  elif ctx.attr.nix_file:
    ctx.symlink(ctx.attr.nix_file, "default.nix")
  elif ctx.attr.nix_file_content:
    expr_args = ["-E", ctx.attr.nix_file_content]
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
  ])

  # If neither repository or path are set, leave empty which will use
  # default value from NIX_PATH.
  path = []
  if ctx.attr.repository and ctx.attr.path:
    fail("'repository' and 'path' attributes are mutually exclusive.")
  elif ctx.attr.repository:
    # XXX Another hack: the repository label typically resolves to
    # some top-level package in the external workspace. So we use
    # dirname to get the actual workspace path.
    path = ["-I", "nixpkgs={0}".format(ctx.path(ctx.attr.repository).dirname)]
  elif ctx.attr.path:
    path = ["-I", "nixpkgs={0}".format(ctx.attr.path)]
  else:
    print("""
WARNING: Implicitly using '<nixpkgs>' as the location of Nixpkgs.
This is not recommended because it makes the build non-hermetic.
Set which Nixpkgs to use explicitly using 'repository' or 'path' attributes.
    """)

  nix_build_path = ctx.which("nix-build")
  if nix_build_path == None:
    fail("Could not find nix-build on the path. Please install it. See: https://nixos.org/nix/")

  nix_build = [nix_build_path] + path + expr_args

  # Large enough integer that Bazel can still parse. We don't have
  # access to MAX_INT and 0 is not a valid timeout so this is as good
  # as we can do.
  timeout = 1073741824
  res = ctx.execute(nix_build, quiet = False, timeout = timeout)
  if res.return_code == 0:
    output_path = res.stdout.splitlines()[-1]
  else:
    fail("Cannot build Nix attribute %s.\nstdout:\n%s\n\nstderr:\n%s\n" %
            (ctx.attr.name, res.stdout, res.stderr)
        )

  # Build a forest of symlinks (like new_local_package() does) to the
  # Nix store.

  find_path = ctx.which("find")
  if find_path == None:
    fail("Could not find the 'find' command. Please ensure it is in your PATH.")

  res = ctx.execute(["find", output_path, "-maxdepth", "1"])
  if res.return_code == 0:
    for i in res.stdout.splitlines():
      basename = i.rpartition("/")[-1]
      ctx.symlink(i, ctx.path(basename))
  else:
    fail(res.stderr)

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
  environ = ["NIX_PATH"],
)

def _cc_configure_custom(ctx):
  overriden_tools = {
    "gcc": ctx.path(ctx.attr.gcc),
    "ld": ctx.path(ctx.attr.ld),
  }
  return cc_autoconf_impl(ctx, overriden_tools)

cc_configure_custom = repository_rule(
  implementation = _cc_configure_custom,
  attrs = {
    "gcc": attr.label(
      executable=True,
      cfg="host",
      allow_single_file=True,
      doc="`gcc` to use in cc toolchain",
    ),
    "ld": attr.label(
      executable=True,
      cfg="host",
      allow_single_file=True,
      doc="`ld` to use in cc toolchain",
    ),
  },
  local = True,
  environ = [
        "ABI_LIBC_VERSION",
        "ABI_VERSION",
        "BAZEL_COMPILER",
        "BAZEL_HOST_SYSTEM",
        "BAZEL_LINKOPTS",
        "BAZEL_PYTHON",
        "BAZEL_SH",
        "BAZEL_TARGET_CPU",
        "BAZEL_TARGET_LIBC",
        "BAZEL_TARGET_SYSTEM",
        "BAZEL_USE_CPP_ONLY_TOOLCHAIN",
        "BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN",
        "BAZEL_USE_LLVM_NATIVE_COVERAGE",
        "BAZEL_VC",
        "BAZEL_VS",
        "CC",
        "CC_CONFIGURE_DEBUG",
        "CC_TOOLCHAIN_NAME",
        "CPLUS_INCLUDE_PATH",
        "CUDA_COMPUTE_CAPABILITIES",
        "CUDA_PATH",
        "GCOV",
        "HOMEBREW_RUBY_PATH",
        "NO_WHOLE_ARCHIVE_OPTION",
        "SYSTEMROOT",
        "USE_DYNAMIC_CRT",
        "USE_MSVC_WRAPPER",
        "VS90COMNTOOLS",
        "VS100COMNTOOLS",
        "VS110COMNTOOLS",
        "VS120COMNTOOLS",
        "VS140COMNTOOLS",
    ],
)
"""Overwrite cc toolchain by supplying custom `gcc` and `ld` (e.g. from
Nix). This allows to fix mismatch of `gcc` versions between what is used by
packages that come from Nix (e.g. `ghc`) and what Bazel detects
automatically (i.e. system-level `gcc`).
"""
