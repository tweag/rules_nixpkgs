load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "get_cpu_value",
)

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
