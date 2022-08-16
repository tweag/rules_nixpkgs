def _interpreter_test_impl(repository_ctx):
    resolved_interpreter = repository_ctx.path(repository_ctx.attr.interpreter_label)

    repository_ctx.file("test.py", executable = False, content = """
import sys
import os

executable_path = os.path.realpath(sys.executable)
interpreter_path = os.path.realpath("{resolved_interpreter}")

print("executable_path = " + executable_path)
print("interpreter_path = " + interpreter_path)

if executable_path != interpreter_path:
    sys.stderr.write("sys.executable different to interpreter target")
    sys.exit(1)
""".format(resolved_interpreter = resolved_interpreter))

    repository_ctx.file("BUILD.bazel", executable = False, content = """
exports_files(["test.py"])
""")

interpreter_test = repository_rule(
    implementation = _interpreter_test_impl,
    attrs = {
        "interpreter_label": attr.label(),
    },
)
