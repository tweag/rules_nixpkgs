package(default_testonly = 1)

sh_test(
  name = "run-hello",
  srcs = ["test_bin.sh"],
  args = ["$(location @hello//:bin)"],
  data = ["@hello//:bin"],
  timeout = "short",
)
