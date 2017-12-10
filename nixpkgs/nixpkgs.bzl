def _nixpkgs_package_impl(ctx):
  attr_path = ctx.attr.attribute_path or ctx.name
  path = ctx.attr.path or '<nixpkgs>'
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
  },
  local = True,
  environ = ["NIX_PATH"],
)
