package(default_testonly = 1)

[sh_test(
  name= "run-{0}".format(test),
  srcs = ["test_bin.sh"],
  args=["$(location @{0}//:bin)".format(test)],
  data = ["@{0}//:bin".format(test)],
  timeout = "short",
) for test in [
    "hello",
    "expr-test",
    "attribute-test",
    "expr-attribute-test",
    "nix-file-test",
    "nix-file-deps-test",
    "nixpkgs-git-repository-test",
]]
