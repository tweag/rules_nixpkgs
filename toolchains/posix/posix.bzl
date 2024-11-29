"""<!-- Edit the docstring in `toolchains/posix/posix.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules for importing a POSIX toolchain from Nixpkgs.

# Rules

* [nixpkgs_sh_posix_configure](#nixpkgs_sh_posix_configure)
"""

load(
    "@rules_nixpkgs_core//:private/get_cpu_value.bzl",
    "get_cpu_value",
)
load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load(
    "@rules_nixpkgs_core//:util.bzl",
    "default_constraints",
    "ensure_constraints",
    "ensure_constraints_pure",
)

def nixpkgs_sh_posix_config(name, packages, **kwargs):
    nixpkgs_package(
        name = name,
        nix_file_content = """
with import <nixpkgs> {{ config = {{}}; overlays = []; }};

let
  # `packages` might include lists, e.g. `stdenv.initialPath` is a list itself,
  # so we need to flatten `packages`.
  flatten = builtins.concatMap (x: if builtins.isList x then x else [x]);
  env = buildEnv {{
    name = "posix-toolchain";
    paths = flatten [ {} ];
  }};
  cmd_glob = "${{env}}/bin/*";
  os = if stdenv.isDarwin then "osx" else "linux";
in

runCommand "bazel-nixpkgs-posix-toolchain"
  {{ executable = false;
    # Pointless to do this on a remote machine.
    preferLocalBuild = true;
    allowSubstitutes = false;
  }}
  ''
    n=$out/nixpkgs_sh_posix.bzl
    mkdir -p "$(dirname "$n")"

    cat >>$n <<EOF
    load("@rules_sh//sh:posix.bzl", "posix", "sh_posix_toolchain")
    discovered = {{
    EOF
    for cmd in ${{cmd_glob}}; do
        if [[ -x $cmd ]]; then
            echo "    '$(basename $cmd)': '$cmd'," >>$n
        fi
    done
    cat >>$n <<EOF
    }}
    def create_posix_toolchain():
        sh_posix_toolchain(
            name = "nixpkgs_sh_posix",
            cmds = {{
                cmd: discovered[cmd]
                for cmd in posix.commands
                if cmd in discovered
            }}
        )
    EOF
  ''
""".format(" ".join(packages)),
        build_file_content = """
load("//:nixpkgs_sh_posix.bzl", "create_posix_toolchain")
create_posix_toolchain()
""",
        **kwargs
    )

# Note [Target constraints for POSIX tools]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# There at least three cases for POSIX tools.
#
# Case 1) The tools are used at build time in the execution platform.
#
# Case 2) The tools are used at runtime time in the target platform
#         when the target platform is the same as the execution
#         platform.
#
# Case 3) The tools are used at runtime time in the target platform
#         when cross-compiling.
#
# At the moment, only (1) and (2) are supported by ignoring any target
# constraints when defining the toolchain. This makes available
# any tools that don't depend on the target platform like grep, find
# or sort. In case (2), the tools are still usable at runtime since
# the platforms match.
#
# POSIX tools that depend on the target platform, like cc and strip,
# are better taken from the Bazel cc toolchain instead, so they do
# match the target platform.
#
# TODO: In order to support (3), where the tools would be needed at
# runtime, nixpkgs_sh_posix_configure will need to be changed to take
# as parameter the constraints for the platform in which the tools
# should run.

def _nixpkgs_sh_posix_toolchain_impl(repository_ctx):
    exec_constraints, _ = ensure_constraints_pure(
        default_constraints = default_constraints(repository_ctx),
        exec_constraints = repository_ctx.attr.exec_constraints,
    )
    repository_ctx.file("BUILD", executable = False, content = """
toolchain(
    name = "nixpkgs_sh_posix_toolchain",
    toolchain = "@{workspace}//:nixpkgs_sh_posix",
    toolchain_type = "@rules_sh//sh/posix:toolchain_type",
    exec_compatible_with = {exec_constraints},
    # Leaving the target constraints empty matter for cross-compilation.
    # See Note [Target constraints for POSIX tools]
    target_compatible_with = [],
)
    """.format(
        workspace = repository_ctx.attr.workspace,
        exec_constraints = exec_constraints,
    ))

_nixpkgs_sh_posix_toolchain = repository_rule(
    _nixpkgs_sh_posix_toolchain_impl,
    attrs = {
        "workspace": attr.string(),
        "exec_constraints": attr.string_list(),
    },
)

def nixpkgs_sh_posix_configure(
        name = "nixpkgs_sh_posix_config",
        packages = ["stdenv.initialPath"],
        exec_constraints = None,
        register = True,
        **kwargs):
    """Create a POSIX toolchain from nixpkgs.

    Loads the given Nix packages, scans them for standard Unix tools, and
    generates a corresponding `sh_posix_toolchain`.

    Make sure to call `nixpkgs_sh_posix_configure` before `sh_posix_configure`,
    if you use both. Otherwise, the local toolchain will always be chosen in
    favor of the nixpkgs one.

    Args:
      name: Name prefix for the generated repositories.
      packages: List of Nix attribute paths to draw Unix tools from.
      exec_constraints: Constraints for the execution platform.
      nix_file_deps: See nixpkgs_package.
      repositories: See nixpkgs_package.
      repository: See nixpkgs_package.
      nixopts: See nixpkgs_package.
      fail_not_supported: See nixpkgs_package.
      register: Automatically register the generated toolchain if set to True.
    """
    nixpkgs_sh_posix_config(
        name = name,
        packages = packages,
        exec_constraints = exec_constraints,
        **kwargs
    )

    # The indirection is required to avoid errors when `nix-build` is not in `PATH`.
    _nixpkgs_sh_posix_toolchain(
        name = name + "_toolchain",
        workspace = name,
    )
    if register:
        native.register_toolchains(
            "@{}//:nixpkgs_sh_posix_toolchain".format(name + "_toolchain"),
        )
