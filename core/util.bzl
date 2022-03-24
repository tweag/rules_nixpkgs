load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")
load("@bazel_skylib//lib:paths.bzl", "paths")

def is_supported_platform(repository_ctx):
    return repository_ctx.which("nix-build") != None

def cp(repository_ctx, src, dest = None):
    """Copy the given file into the external repository root.

    Args:
      repository_ctx: The repository context of the current repository rule.
      src: The source file. Must be a Label if dest is None.
      dest: Optional, The target path within the current repository root.
        By default the relative path to the repository root is preserved.

    Returns:
      The dest value
    """
    if dest == None:
        if type(src) != "Label":
            fail("src must be a Label if dest is not specified explicitly.")
        dest = "/".join([
            component
            for component in [src.workspace_root, src.package, src.name]
            if component
        ])

    # Copy the file
    repository_ctx.file(
        repository_ctx.path(dest),
        repository_ctx.read(repository_ctx.path(src)),
        executable = False,
        legacy_utf8 = False,
    )

    # Copy the executable bit of the source
    # This is important to ensure that copied binaries are executable.
    # Windows may not have chmod in path and doesn't have executable bits anyway.
    if get_cpu_value(repository_ctx) != "x64_windows":
        repository_ctx.execute([
            repository_ctx.which("chmod"),
            "--reference",
            repository_ctx.path(src),
            repository_ctx.path(dest),
        ])

    return dest

def execute_or_fail(repository_ctx, arguments, failure_message = "", *args, **kwargs):
    """Call repository_ctx.execute() and fail if non-zero return code."""
    result = repository_ctx.execute(arguments, *args, **kwargs)
    if result.return_code:
        outputs = dict(
            failure_message = failure_message,
            arguments = arguments,
            return_code = result.return_code,
            stderr = result.stderr,
        )
        fail("""
{failure_message}
Command: {arguments}
Return code: {return_code}
Error output:
{stderr}
""".format(**outputs))
    return result

def label_string(label):
    """Convert the given (optional) Label to a string."""
    if not label:
        return "None"
    else:
        return '"%s"' % label

def executable_path(repository_ctx, exe_name, extra_msg = ""):
    """Try to find the executable, fail with an error."""
    path = repository_ctx.which(exe_name)
    if path == None:
        fail("Could not find the `{}` executable in PATH.{}\n"
            .format(exe_name, " " + extra_msg if extra_msg else ""))
    return path

def find_children(repository_ctx, target_dir):
    find_args = [
        executable_path(repository_ctx, "find"),
        "-L",
        target_dir,
        "-maxdepth",
        "1",
        # otherwise the directory is printed as well
        "-mindepth",
        "1",
        # filenames can contain \n
        "-print0",
    ]
    exec_result = execute_or_fail(repository_ctx, find_args)
    return exec_result.stdout.rstrip("\000").split("\000")

def ensure_constraints(repository_ctx):
    """Build exec and target constraints for repository rules.

    If these are user-provided, then they are passed through.
    Otherwise we build for the current CPU on the current OS, one of darwin-x86_64, darwin-arm64, or the default linux-x86_64.
    In either case, exec_constraints always contain the support_nix constraint, so the toolchain can be rejected on non-Nix environments.

    Args:
      repository_ctx: The repository context of the current repository rule.

    Returns:
      exec_constraints, The generated list of exec constraints
      target_constraints, The generated list of target constraints
    """
    cpu = get_cpu_value(repository_ctx)
    cpu = {
        "darwin": "@platforms//cpu:x86_64",
        "darwin_arm64": "@platforms//cpu:arm64",
    }.get(cpu, "@platforms//cpu:x86_64")
    os = {
        "darwin": "@platforms//os:osx",
        "darwin_arm64": "@platforms//os:osx",
    }.get(cpu, "@platforms//os:linux")
    if not repository_ctx.attr.target_constraints and not repository_ctx.attr.exec_constraints:
        target_constraints = [cpu, os]
        exec_constraints = target_constraints
    else:
        target_constraints = list(repository_ctx.attr.target_constraints)
        exec_constraints = list(repository_ctx.attr.exec_constraints)
    exec_constraints.append("@rules_nixpkgs_core//constraints:support_nix")
    return exec_constraints, target_constraints

def parse_expand_location(string):
    """Parse a string that might contain location expansion commands.

    Generates a list of pairs of command and argument.
    The command can have the following values:
    - `string`: argument is a string, append it to the result.
    - `location`: argument is a label, append its location to the result.

    Attrs:
      string: string, The string to parse.

    Returns:
      (result, error):
        result: The generated list of pairs of command and argument.
        error: string or None, This is set if an error occurred.
    """
    result = []
    offset = 0
    len_string = len(string)

    # Step through occurrences of `$`. This is bounded by the length of the string.
    for _ in range(len_string):
        # Find the position of the next `$`.
        position = string.find("$", offset)
        if position == -1:
            position = len_string

        # Append the in-between literal string.
        if offset < position:
            result.append(("string", string[offset:position]))

        # Terminate at the end of the string.
        if position == len_string:
            break

        # Parse the `$` command.
        if string[position:].startswith("$$"):
            # Insert verbatim '$'.
            result.append(("string", "$"))
            offset = position + 2
        elif string[position:].startswith("$("):
            # Expand a location command.
            group_start = position + 2
            group_end = string.find(")", group_start)
            if group_end == -1:
                return (None, "Unbalanced parentheses in location expansion for '{}'.".format(string[position:]))

            group = string[group_start:group_end]
            command = None
            if group.startswith("location "):
                label_str = group[len("location "):]
                command = ("location", label_str)
            else:
                return (None, "Unrecognized location expansion '$({})'.".format(group))

            result.append(command)
            offset = group_end + 1
        else:
            return (None, "Unescaped '$' in location expansion at position {} of input.".format(position))

    return (result, None)

def resolve_label(label_str, labels):
    """Find the label that corresponds to the given string.

    Attr:
      label_str: string, String representation of a label.
      labels: dict from Label to path: Known label to path mappings.

    Returns:
      (path, error):
        path: path, The path to the resolved label
        error: string or None, This is set if an error occurred.
    """
    label_candidates = [
        (lbl, path)
        for (lbl, path) in labels.items()
        if lbl.relative(label_str) == lbl
    ]

    if len(label_candidates) == 0:
        return (None, "Unknown label '{}' in location expansion.".format(label_str))
    elif len(label_candidates) > 1:
        return (None, "Ambiguous label '{}' in location expansion. Candidates: {}".format(
            label_str,
            ", ".join([str(lbl) for (lbl, _) in label_candidates]),
        ))

    return (label_candidates[0][1], None)

def expand_location(repository_ctx, string, labels, attr = None):
    """Expand `$(location label)` to a path.

    Raises an error on unexpected occurrences of `$`.
    Use `$$` to insert a verbatim `$`.

    Attrs:
      repository_ctx: The repository rule context.
      string: string, Replace instances of `$(location )` in this string.
      labels: dict from label to path: Known label to path mappings.
      attr: string, The rule attribute to use for error reporting.

    Returns:
      The string with all instances of `$(location )` replaced by paths.
    """
    (parsed, error) = parse_expand_location(string)
    if error != None:
        fail(error, attr)

    result = ""
    for (command, argument) in parsed:
        if command == "string":
            result += argument
        elif command == "location":
            (label, error) = resolve_label(argument, labels)
            if error != None:
                fail(error, attr)

            result += paths.join(".", paths.relativize(
                str(repository_ctx.path(label)),
                str(repository_ctx.path(".")),
            ))
        else:
            fail("Internal error: Unknown location expansion command '{}'.".format(command), attr)

    return result
