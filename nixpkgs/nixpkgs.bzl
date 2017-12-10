def _nixpkgs_package_impl(ctx):
  path = '<nixpkgs>'
  if ctx.attr.revision and ctx.attr.path:
    fail("'revision' and 'path' fields are mutually exclusive.")
  if ctx.attr.revision:
    path = "nixpkgs"
    ctx.download_and_extract(
      url = "https://github.com/NixOS/nixpkgs/archive/%s.tar.gz" % ctx.attr.revision,
      output = path,
      stripPrefix = "nixpkgs-" + ctx.attr.revision,
    )
  if ctx.attr.path:
    path = ctx.attr.path
  attr_path = ctx.attr.attribute_path or ctx.name
  res = ctx.execute(["nix-build", path, "-A", attr_path, "--no-out-link"])
  if res.return_code == 0:
    path = res.stdout.splitlines()[-1]
  else:
    fail("Cannot build Nix attribute %s." % ctx.attr.name)
  ctx.symlink(path, "nix")
  if ctx.attr.build_file and ctx.attr.build_file_content:
    fail("Specify one of 'build_file' or 'build_file_content', but not both.")
  elif ctx.attr.build_file:
    ctx.symlink(ctx.attr.build_file, "BUILD")
  elif ctx.attr.build_file_content:
    ctx.file("BUILD", content = ctx.attr.build_file_content)
  else:
    ctx.template("BUILD", Label("@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"))

nixpkgs_package = repository_rule(
  implementation = _nixpkgs_package_impl,
  attrs = {
    "attribute_path": attr.string(),
    "path": attr.string(),
    "revision": attr.string(),
    "build_file": attr.string(),
    "build_file_content": attr.string(),
  },
  local = True,
  environ = ["NIX_PATH"],
)
