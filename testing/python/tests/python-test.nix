with import <nixpkgs> { config = {}; overlays = []; };
runCommand "test-nixpkgs-python-toolchain"
  { executable = false; }
  ''
    mkdir -p $out

    cat >$out/BUILD.bazel <<'EOF_BUILD'
    py_test(
        name = "python2-test",
        main = "python-test.py",
        srcs = ["python-test.py"],
        python_version = "PY2",
        srcs_version = "PY2",
        visibility = ["//visibility:public"],
    )
    py_test(
        name = "python3-test",
        main = "python-test.py",
        srcs = ["python-test.py"],
        python_version = "PY3",
        srcs_version = "PY3",
        visibility = ["//visibility:public"],
    )
    EOF_BUILD

    cat >$out/python-test.py <<'EOF_PYTHON'
    import os
    import sys

    _failure_message = """\
    Python interpreter is not provided by the toolchain.
    Expected: '{expected}'
    Actual:   '{actual}'.
    """

    if __name__ == "__main__":
        if sys.version_info.major == 2:
            python_bin = "${python2}/bin/python"
        else:
            python_bin = "${python3}/bin/python"
        if not sys.executable == python_bin:
            sys.stderr.write(_failure_message.format(
                expected = python_bin,
                actual = sys.executable,
            ))
            sys.exit(1)
    EOF_PYTHON
  ''
