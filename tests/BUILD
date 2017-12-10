package(default_testonly = 1)

sh_test(
  name = "RunGHC",
  srcs = ["test_bin.sh"],
  args = ["$(location @jq//:jq)", "--version"],
  data = ["@jq//:jq"],
  timeout = "short",
)
  
