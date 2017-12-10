def _nixpkgs_package_impl(ctx):
  path = '<nixpkgs>'
  if ctx.attr.revision and ctx.attr.path:
    fail("'revision' and 'path' fields are mutually exclusive.")
  if ctx.attr.revision:
    path = "nixpkgs"
    ctx.download_and_extract(
      url = "https://github.com/NixOS/nixpkgs/archive/%s.tar.gz" % ctx.attr.revision,
      output = path,
      strip_prefix = "nixpkgs-" + ctx.attr.revision,
    )
  if ctx.attr.path:
    path = ctx.attr.path
  attr_path = ctx.attr.attribute_path or ctx.name
  res = ctx.execute(["nix-build", path, "-A", attr_path, "--no-out-link"])
  if res.return_code == 0:
    path = res.stdout.splitlines()[-1]
  else:
    fail("Cannot build Nix attribute %s." % ctx.attr.name)
  ctx.template(
    "BUILD",
    Label("@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"),
  )
  ctx.symlink(path, "nix")

nixpkgs_package = repository_rule(
  implementation = _nixpkgs_package_impl,
  attrs = {
    "attribute_path": attr.string(),
    "path": attr.string(),
    "revision": attr.string(),
  },
  local = True,
  environ = ["NIX_PATH"],
)
