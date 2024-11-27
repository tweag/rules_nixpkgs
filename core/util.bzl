load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:versions.bzl", "versions")

# see https://github.com/tweag/rules_nixpkgs/pull/613
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L225
def get_cpu_value(repository_ctx):
    """Compute the cpu_value based on the OS name. Doesn't %-escape the result!

    Args:
      repository_ctx: The repository context.
    Returns:
      One of (darwin, freebsd, x64_windows, ppc, s390x, arm, aarch64, k8, piii)
    """
    os_name = repository_ctx.os.name
    arch = repository_ctx.os.arch
    if os_name.startswith("mac os"):
        # Check if we are on x86_64 or arm64 and return the corresponding cpu value.
        return "darwin_" + ("arm64" if arch == "aarch64" else "x86_64")
    if os_name.find("freebsd") != -1:
        return "freebsd"
    if os_name.find("openbsd") != -1:
        return "openbsd"
    if os_name.find("windows") != -1:
        if arch == "aarch64":
            return "arm64_windows"
        else:
            return "x64_windows"

    if arch in ["power", "ppc64le", "ppc", "ppc64"]:
        return "ppc"
    if arch in ["s390x"]:
        return "s390x"
    if arch in ["mips64"]:
        return "mips64"
    if arch in ["riscv64"]:
        return "riscv64"
    if arch in ["arm", "armv7l"]:
        return "arm"
    if arch in ["aarch64"]:
        return "aarch64"
    return "k8" if arch in ["amd64", "x86_64", "x64"] else "piii"

def fail_on_err(return_value, prefix = None):
    """Fail if the given return value indicates an error.

    Args:
      return_value: Pair; If the second element is not `None` this indicates an error.
      prefix: optional, String; A prefix for the error message contained in `return_value`.

    Returns:
      The first element of `return_value` if no error was indicated.
    """
    result, err = return_value

    if err:
        if prefix:
            msg = prefix + err
        else:
            msg = err
        fail(msg)

    return result

def is_supported_platform(repository_ctx):
    return repository_ctx.which("nix-build") != None

def _is_executable(repository_ctx, path):
    stat_exe = repository_ctx.which("stat")
    if stat_exe == None:
        return False

    # A hack to detect if stat in Nix shell is BSD stat as BSD stat does not
    # support --version flag
    is_bsd_stat = repository_ctx.execute([stat_exe, "--version"]).return_code != 0
    if is_bsd_stat:
        stat_args = ["-f", "%Lp", path]
    else:
        stat_args = ["-c", "%a", path]

    arguments = [stat_exe] + stat_args
    exec_result = repository_ctx.execute(arguments)
    stdout = exec_result.stdout.strip()
    mode = int(stdout, 8)
    return mode & 0o100 != 0

def external_repository_root(label):
    """Get path to repository root from label."""
    return "/".join([
        component
        for component in [label.workspace_root, label.package, label.name]
        if component
    ])

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
        dest = external_repository_root(src)

    src_path = repository_ctx.path(src)
    dest_path = repository_ctx.path(dest)
    executable = _is_executable(repository_ctx, src_path)

    # Copy the file
    repository_ctx.file(
        dest_path,
        repository_ctx.read(src_path),
        executable = executable,
        legacy_utf8 = False,
    )

    return dest

def execute_or_fail(repository_ctx, arguments, failure_message = "", *args, **kwargs):
    """Call repository_ctx.execute() and fail if non-zero return code."""
    result = repository_ctx.execute(arguments, *args, **kwargs)
    if result.return_code:
        outputs = dict(
            failure_message = failure_message,
            command = " ".join([repr(str(a)) for a in arguments]),
            return_code = result.return_code,
            stderr = '      > '.join(('\n'+result.stderr).splitlines(True)),
        )
        fail("""
  {failure_message}
    Command: {command}
    Return code: {return_code}
    Error output: {stderr}
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
    if exec_result.stdout != "":
        return exec_result.stdout.rstrip("\000").split("\000")
    else:
        return []  # Special case because splitting the empty string yields [""]

def default_constraints(repository_ctx):
    """Calculate the default CPU and OS constraints based on the host platform.

    Args:
      repository_ctx: The repository context of the current repository rule.

    Returns:
      A list containing the cpu and os constraints.
    """
    cpu_value = get_cpu_value(repository_ctx)
    cpu = {
        "darwin": "@platforms//cpu:x86_64",
        "darwin_x86_64": "@platforms//cpu:x86_64",
        "darwin_arm64": "@platforms//cpu:arm64",
        "aarch64": "@platforms//cpu:arm64",
    }.get(cpu_value, "@platforms//cpu:x86_64")
    os = {
        "darwin": "@platforms//os:osx",
        "darwin_arm64": "@platforms//os:osx",
        "darwin_x86_64": "@platforms//os:osx",
    }.get(cpu_value, "@platforms//os:linux")
    return [cpu, os]

def ensure_constraints_pure(default_constraints, target_constraints = [], exec_constraints = []):
    """Build exec and target constraints for repository rules.

    If these are user-provided, then they are passed through.
    Otherwise, use the provided default constraints.
    In either case, exec_constraints always contain the support_nix constraint, so the toolchain can be rejected on non-Nix environments.

    Args:
      target_constraints: optional, User provided target_constraints.
      exec_constraints: optional, User provided exec_constraints.
      default_constraints: Fall-back constraints.

    Returns:
      exec_constraints, The generated list of exec constraints
      target_constraints, The generated list of target constraints
    """
    if not target_constraints and not exec_constraints:
        target_constraints = default_constraints
        exec_constraints = target_constraints
    else:
        target_constraints = list(target_constraints)
        exec_constraints = list(exec_constraints)
    exec_constraints.append("@rules_nixpkgs_core//constraints:support_nix")
    return exec_constraints, target_constraints

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
    return ensure_constraints_pure(
        default_constraints = default_constraints(repository_ctx),
        target_constraints = repository_ctx.attr.target_constraints,
        exec_constraints = repository_ctx.attr.exec_constraints,
    )

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
      labels: dict from String to path: Known label-string to path mappings.

    Returns:
      (path, error):
        path: path, The path to the resolved label
        error: string or None, This is set if an error occurred.
    """
    label_candidates = [
        (lbl_str, path)
        for (lbl_str, path) in labels.items()
        if Label(lbl_str).relative(label_str) == Label(lbl_str)
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
      labels: dict from string to path: Known label-string to path mappings.
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
            (path, error) = resolve_label(argument, labels)
            if error != None:
                fail(error, attr)

            result += paths.join(".", paths.relativize(
                str(repository_ctx.path(path)),
                str(repository_ctx.path(".")),
            ))
        else:
            fail("Internal error: Unknown location expansion command '{}'.".format(command), attr)

    return result

def is_bazel_version_at_least(threshold):
    """ Check if current bazel version is higer or equals to a threshold.

    Args:
        threshold: string: minimum desired version of Bazel

    Returns:
        threshold_met, from_source_version: bool, bool: tuple where
        first item states if the threshold was met, the second indicates
        if obtained bazel version is empty string (indicating from source build)
    """
    threshold_met = False
    from_source_version = False

    bazel_version = versions.get()
    if not bazel_version:
        from_source_version = True
    else:
        threshold_met = versions.is_at_least(threshold, bazel_version)

    return (
        threshold_met,
        from_source_version,
    )
