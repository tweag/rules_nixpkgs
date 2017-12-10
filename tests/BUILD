package(default_testonly = 1)

sh_test(
  name = "run-jq",
  srcs = ["test_bin.sh"],
  args = ["$(location @jq//:bin)", "--version"],
  data = ["@jq//:bin"],
  timeout = "short",
)
  
