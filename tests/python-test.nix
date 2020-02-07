with import <nixpkgs> { config = {}; overlays = []; };
runCommand "test-nixpkgs-python-toolchain"
  { executable = false; }
  ''
    mkdir -p $out

    cat >$out/BUILD.bazel <<'EOF_BUILD'
    py_test(
        name = "python-test",
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
        python_bin = "${python3}/bin/python"
        if not sys.executable == python_bin:
            print(_failure_message.format(
                expected = python_bin,
                actual = sys.executable,
            ), file=sys.stderr)
            sys.exit(1)
    EOF_PYTHON
  ''
