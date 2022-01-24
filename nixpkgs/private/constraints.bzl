load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")

def ensure_constraints(repository_ctx):
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
