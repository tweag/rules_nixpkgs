import os
import sys

_failure_message = """\
Python interpreter is not provided by the toolchain.
Expected: '{expected}'
Actual:   '{actual}'.
"""

if __name__ == "__main__":
    runfiles_dir = os.environ["RUNFILES_DIR"]
    python_bin = os.path.join(
        runfiles_dir, "nixpkgs_python_toolchain_python3", "bin", "python")
    if not sys.executable == python_bin:
        print(_failure_message.format(
            expected = python_bin,
            actual = sys.executable,
        ), file=sys.stderr)
        sys.exit(1)
