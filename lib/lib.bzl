def executable_path(exe_name, rep_ctx, extra_msg=""):
    """Try to find the executable, fail with an error."""
    path = rep_ctx.which(exe_name)
    if path == None:
        fail("Could not find the `{}` executable in PATH.{}\n"
            .format(exe_name, " " + extra_msg if extra_msg else ""))
    return path


def execute_error(exec_result, msg):
    """Print a nice error message for a failed `execute`."""
    fail("""
execute() error: {msg}
status code: {code}
stdout:
{stdout}
stderr:
{stderr}
""".format(
    msg=msg,
    code=exec_result.return_code,
    stdout=exec_result.stdout,
    stderr=exec_result.stderr))


def symlink_children(target_dir, link_dir, rep_ctx):
    """Create a symlink to all children of `target_dir` in the current
    build directory."""
    find_args = [
        executable_path("find", rep_ctx),
        target_dir,
        "-maxdepth", "1",
        # otherwise the directory is printed as well
        "-mindepth", "1",
        # filenames can contain \n
        "-print0",
    ]
    find_res = rep_ctx.execute(find_args)
    if find_res.return_code == 0:
        for target in find_res.stdout.rstrip("\0").split("\0"):
            rep_ctx.symlink(
                target,
                join_path(link_dir, basename(target)))
    else:
        execute_error(find_res)


# TODO copied from skylib.paths

def join_path(path, *others):
    result = path
    for p in others:
        if _is_absolute(p):
            result = p
        elif not result or result.endswith("/"):
            result += p
        else:
            result += "/" + p
    return result

def _is_absolute(path):
    return path.startswith("/") or (len(path) > 2 and path[1] == ":")

def basename(p):
    return p.rpartition("/")[-1]
