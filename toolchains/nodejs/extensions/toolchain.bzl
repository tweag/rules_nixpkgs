"""Defines the nix_nodejs module extension.
"""

load(
    "//private:common.bzl",
    "DEFAULT_PLATFORMS_MAPPING",
    "nixpkgs_nodejs",
    "nodejs_toolchain",
)

_DEFAULT_NIXPKGS = "@nixpkgs"
_DEFAULT_ATTR = "nodejs"

_TOOLCHAINS_REPO = "nixpkgs_nodejs_toolchains"
_NODEJS_REPO = "nixpkgs_nodejs_{platform}"
_NODEJS_LABEL = "@{repo}//:nodejs_nix_impl"

def _nodejs_label(repo_name):
    return _NODEJS_LABEL.format(repo = repo_name)

def _toolchain_name(*, name, count, prefix_digits):
    prefix = str(count)
    prefix = "0" * (prefix_digits - len(prefix)) + prefix
    return prefix + "-" + name

def _toolchains_repo_impl(repository_ctx):
    num_toolchains = len(repository_ctx.attr.labels)
    prefix_digits = len(str(num_toolchains))

    sequence = zip(
        repository_ctx.attr.names,
        repository_ctx.attr.labels,
        repository_ctx.attr.exec_lengths,
        repository_ctx.attr.target_lengths,
    )

    exec_offset = 0
    target_offset = 0
    builder = []

    for count, (name, label, exec_length, target_length) in enumerate(sequence, start = 1):
        name = _toolchain_name(
            name = name,
            count = count,
            prefix_digits = prefix_digits,
        )
        exec_end = exec_offset + exec_length
        exec_constraints = repository_ctx.attr.exec_constraints[exec_offset:exec_end]
        exec_offset = exec_end
        target_end = target_offset + target_length
        target_constraints = repository_ctx.attr.target_constraints[target_offset:target_end]
        target_offset = target_end
        builder.append(nodejs_toolchain(
            name = name,
            label = label,
            exec_constraints = exec_constraints,
            target_constraints = target_constraints,
        ))

    repository_ctx.file(
        "BUILD.bazel",
        content = "\n".join(builder),
        executable = False,
    )

_toolchains_repo = repository_rule(
    _toolchains_repo_impl,
    attrs = {
        "names": attr.string_list(),
        "labels": attr.string_list(),
        "exec_constraints": attr.string_list(),
        "exec_lengths": attr.int_list(),
        "target_constraints": attr.string_list(),
        "target_lengths": attr.int_list(),
    },
)

def _nix_nodejs_impl(module_ctx):
    toolchain_names = []
    toolchain_labels = []
    toolchain_exec_constraints = []
    toolchain_exec_lengths = []
    toolchain_target_constraints = []
    toolchain_target_lengths = []

    for nix_platform, bazel_platform in DEFAULT_PLATFORMS_MAPPING.items():
        name = bazel_platform.rules_nodejs_platform
        repo_name = _NODEJS_REPO.format(platform = bazel_platform.rules_nodejs_platform)
        exec_constraints = [str(Label(c)) for c in bazel_platform.exec_constraints]
        target_constraints = [str(Label(c)) for c in bazel_platform.target_constraints]

        nixpkgs_nodejs(
            name = repo_name,
            nix_platform = nix_platform,
            attribute_path = _DEFAULT_ATTR,
            repository = _DEFAULT_NIXPKGS,
        )

        toolchain_names.append(name)
        toolchain_labels.append(_nodejs_label(repo_name))
        toolchain_exec_constraints.extend(exec_constraints)
        toolchain_exec_lengths.append(len(exec_constraints))
        toolchain_target_constraints.extend(target_constraints)
        toolchain_target_lengths.append(len(target_constraints))

    _toolchains_repo(
        name = _TOOLCHAINS_REPO,
        names = toolchain_names,
        labels = toolchain_labels,
        exec_constraints = toolchain_exec_constraints,
        exec_lengths = toolchain_exec_lengths,
        target_constraints = toolchain_target_constraints,
        target_lengths = toolchain_target_lengths,
    )

nix_nodejs = module_extension(
    _nix_nodejs_impl,
    tag_classes = {
    },
)
