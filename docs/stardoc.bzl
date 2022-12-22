load("@io_bazel_stardoc//stardoc:stardoc.bzl", _stardoc = "stardoc")

def generate_documentation(
        name,
        input,
        error_message = None,
        **kwargs):
    """
    rules for rendering library documentation

    creates rules for
    - generating library documentation
    - copying a file into the source tree containing it
    - testing that the copying has actually happened
        (since the copy rule must be run manually)

    Args:
        name: target file name for rendered documentation.
        input: file name to render documentation from
        error_message: custom error message to print if rendered documentation is not up to date.
        **kwargs: arguments for `stardoc`, most notably `symbol_names` to generate documentation for.
    """

    # generate documentation into transient file
    out = "_{}".format(name)
    stardoc("__{}".format(name), out, input, **kwargs)

    # create rule to copy documentation into source tree
    # has to be run manually! set up a commit hook for convenience?
    copy_files(
        name = "update-{}".format(name),
        data = [(out, name)],
    )

    if not error_message:
        error_message = [
            "{} is not up to date.",
            "Please update it using the following command:",
            "",
            "bazel run //{}:update-{}",
        ]
        error_message = "\n".join(error_message).format(name, native.package_name(), name)

    # create test that source tree is up to date with rendered documentation
    compare_files(
        name = "check-{}".format(name),
        # expect target file at top level of current workspace, see `copy_files`
        data = [(out, to_root(name))],
        error_message = error_message,
    )

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
        srcs = ["@io_tweag_rules_nixpkgs//docs:copy-files.sh"],
        args = ["$(location {}) {}".format(a, b) for a, b in data],
        data = [a for a, b in data],
        # pass `cp` from `coreutils`, so that it is not something arbitrary
        env = {"POSIX_CP": "$(POSIX_CP)"},
        toolchains = ["@rules_sh//sh/posix:make_variables"],
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
        srcs = ["@io_tweag_rules_nixpkgs//docs:compare-files.sh"],
        args = ["$(location {})".format(f) for f in data],
        data = data,
        env = {"errormsg": error_message},
    )

def to_root(label):
    return "//:" + Label(absolute_label(label)).name

def absolute_label(label):
    # adapted from https://stackoverflow.com/a/66705640/18406610
    if label.startswith("@") or label.startswith("/"):
        return label
    if label.startswith(":"):
        return native.repository_name() + "//" + native.package_name() + label
    return native.repository_name() + "//" + native.package_name() + ":" + label
