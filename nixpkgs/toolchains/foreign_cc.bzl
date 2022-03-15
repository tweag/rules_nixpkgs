# alias to Bazel module `toolchains/cc`
load("@rules_nixpkgs_cc//:foreign_cc.bzl", _nixpkgs_foreign_cc_configure = "nixpkgs_foreign_cc_configure")

nixpkgs_foreign_cc_configure = _nixpkgs_foreign_cc_configure
