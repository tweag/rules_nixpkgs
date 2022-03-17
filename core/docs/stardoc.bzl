load("@io_bazel_stardoc//stardoc:stardoc.bzl", _stardoc = "stardoc")

def generate(
        name,
        input,
        error_message = None,
        **kwargs):
    """
    create rules for generating documentation, copying a file into the source
    tree containing it, and testing that the copying has actually happened
    (since the copy rule must be run manually).
    """
    if not error_message:
        error_message = [
            "{} is not up to date.",
            "Please update it using the following command:",
            "",
            "bazel run //{}:update-{}",
        ]
        error_message = "\n".join(error_message).format(name, native.package_name(), name)
    out = "_{}".format(name)
    stardoc("__{}".format(name), out, input, **kwargs)
    copy_files(
        name = "update-{}".format(name),
        data = [(out, name)],
    )
    compare_files(
        name = "check-{}".format(name),
        data = [(out, name)],
        error_message = error_message,
    )

def stardoc(
        name,
        out,
        input,
        aspect_template = "@rules_nixpkgs_core//docs:templates/aspect.vm",
        func_template = "@rules_nixpkgs_core//docs:templates/func.vm",
        header_template = "@rules_nixpkgs_core//docs:templates/header.vm",
        provider_template = "@rules_nixpkgs_core//docs:templates/provider.vm",
        rule_template = "@rules_nixpkgs_core//docs:templates/rule.vm",
        **kwargs):
    _stardoc(
        name = name,
        out = out,
        input = input,
        aspect_template = aspect_template,
        func_template = func_template,
        header_template = header_template,
        provider_template = provider_template,
        rule_template = rule_template,
        **kwargs
    )

def copy_files(name, data):
    """copy list of files to workspace root"""
    native.sh_binary(
        name = name,
        srcs = ["@rules_nixpkgs_core//docs:copy-files.sh"],
        args = ["$(location {}) {}".format(a, b) for a, b in data],
        data = [f for pair in data for f in pair],
    )

def compare_files(name, data, error_message = ""):
    """
    compare pairs of files for content equality.
    print error message if a pair does not match.
    """

    # flatten pairs, as there is no meaningful way to work with anything but
    # strings in `bash`
    data = [f for pair in data for f in pair]
    native.sh_test(
        name = name,
        srcs = ["@rules_nixpkgs_core//docs:compare-files.sh"],
        args = ["$(location {})".format(f) for f in data],
        data = data,
        env = {"errormsg": error_message},
    )
