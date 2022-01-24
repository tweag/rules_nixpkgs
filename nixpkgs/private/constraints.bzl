load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")

def ensure_constraints(repository_ctx):
    """Build exec and target constraints for repository rules.

    If these are user-provided, then they are passed through. Otherwise we build for x86_64 on the current OS.
    In either case, exec_constraints always contain the support_nix constraint, so the toolchain can be rejected on non-Nix environments.

    Args:
      repository_ctx: The repository context of the current repository rule.

    Returns:
      exec_constraints, The generated list of exec constraints
      target_constraints, The generated list of target constraints
    """
    cpu = get_cpu_value(repository_ctx)
    os = {"darwin": "osx"}.get(cpu, "linux")
    if not repository_ctx.attr.target_constraints and not repository_ctx.attr.exec_constraints:
        target_constraints = ["@platforms//cpu:x86_64"]
        target_constraints.append("@platforms//os:{}".format(os))
        exec_constraints = target_constraints
    else:
        target_constraints = list(repository_ctx.attr.target_constraints)
        exec_constraints = list(repository_ctx.attr.exec_constraints)
    exec_constraints.append("@io_tweag_rules_nixpkgs//nixpkgs/constraints:support_nix")
    return exec_constraints, target_constraints
