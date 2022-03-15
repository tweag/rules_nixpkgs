load("@io_bazel_stardoc//stardoc:stardoc.bzl", _stardoc = "stardoc")

def stardoc(
        name,
        out,
        input,
        aspect_template = "@io_tweag_rules_nixpkgs//docs:templates/aspect.vm",
        func_template = "@io_tweag_rules_nixpkgs//docs:templates/func.vm",
        header_template = "@io_tweag_rules_nixpkgs//docs:templates/header.vm",
        provider_template = "@io_tweag_rules_nixpkgs//docs:templates/provider.vm",
        rule_template = "@io_tweag_rules_nixpkgs//docs:templates/rule.vm",
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
        srcs = ["copy-files.sh"],
        args = ["$(location {}) {}".format(f, f) for f in data],
        data = data,
    )

def compare_files(name, data, error_message=""):
    """
    compare pairs of files for content equality.
    print error message if a pair does not match.
    """

    # flatten pairs, as there is no meaningful way to work with anything but
    # strings in `bash`
    data = [f for pair in data for f in pair]
    native.sh_test(
        name = name,
        srcs = ["compare-files.sh"],
        args = ["$(location {})".format(f) for f in data],
        data = data,
        env = {"errormsg" : error_message},
    )