workspace(name = "io_tweag_rules_nixpkgs")

load("//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_cc_configure",
    "nixpkgs_git_repository",
    "nixpkgs_local_repository",
    "nixpkgs_package",
    "nixpkgs_python_configure",
    "nixpkgs_sh_posix_configure",
)

# For tests

nixpkgs_git_repository(
    name = "remote_nixpkgs",
    remote = "https://github.com/NixOS/nixpkgs",
    revision = "18.09",
    sha256 = "6451af4083485e13daa427f745cbf859bc23cb8b70454c017887c006a13bd65e",
)

nixpkgs_local_repository(
    name = "nixpkgs",
    nix_file = "//:nixpkgs.nix",
    nix_file_deps = ["//:nixpkgs.json"],
)

nixpkgs_package(
    name = "nixpkgs-git-repository-test",
    attribute_path = "hello",
    repositories = {"nixpkgs": "@remote_nixpkgs"},
)

nixpkgs_package(
    name = "hello",
    # Deliberately not repository, to test whether repositories works.
    repositories = {"nixpkgs": "@nixpkgs"},
)

nixpkgs_package(
    name = "expr-test",
    nix_file_content = "let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in pkgs.hello",
    nix_file_deps = ["//:nixpkgs.json"],
    # Deliberately not @nixpkgs, to test whether explict file works.
    repositories = {"nixpkgs": "//:nixpkgs.nix"},
)

nixpkgs_package(
    name = "attribute-test",
    attribute_path = "hello",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "expr-attribute-test",
    attribute_path = "hello",
    nix_file_content = "import <nixpkgs> { config = {}; overlays = []; }",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "nix-file-test",
    attribute_path = "hello",
    nix_file = "//tests:nixpkgs.nix",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "nix-file-deps-test",
    nix_file = "//tests:hello.nix",
    nix_file_deps = ["//tests:pkgname.nix"],
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "output-filegroup-test",
    nix_file = "//tests:output.nix",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "extra-args-test",
    nix_file_content = """
{ packagePath }: (import <nixpkgs> { config = {}; overlays = []; }).${packagePath}
    """,
    nixopts = [
        "--argstr",
        "packagePath",
        "hello",
    ],
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "output-filegroup-manual-test",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
filegroup(
    name = "manual-filegroup",
    srcs = glob(["hi-i-exist", "hi-i-exist-too", "bin/*"]),
)
""",
    nix_file = "//tests:output.nix",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "relative-imports",
    attribute_path = "hello",
    nix_file = "//tests:relative_imports.nix",
    nix_file_deps = [
        "//:nixpkgs.json",
        "//:nixpkgs.nix",
        "//tests:relative_imports/nixpkgs.nix",
    ],
    repository = "@nixpkgs",
)

# This bazel build @output-derivation-is-a-file//... must fail
# See https://github.com/tweag/rules_nixpkgs/issues/99 for details
nixpkgs_package(
    name = "output-derivation-is-a-file",
    attribute_path = "",
    nix_file_content = """let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in pkgs.writeText "foo" "bar" """,
    nix_file_deps = [
        "//:nixpkgs.json",
        "//:nixpkgs.nix",
        "//tests:relative_imports/nixpkgs.nix",
    ],
    repository = "@nixpkgs",
)

nixpkgs_cc_configure(repository = "@remote_nixpkgs")

nixpkgs_python_configure(
    python2_attribute_path = "python2",
    repository = "@remote_nixpkgs",
)

nixpkgs_package(
    name = "nixpkgs_python_configure_test",
    nix_file = "//tests:python-test.nix",
    repository = "@remote_nixpkgs",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_sh",
    sha256 = "2613156e96b41fe0f91ac86a65edaea7da910b7130f2392ca02e8270f674a734",
    strip_prefix = "rules_sh-0.1.0",
    urls = ["https://github.com/tweag/rules_sh/archive/v0.1.0.tar.gz"],
)

load("@rules_sh//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()

nixpkgs_sh_posix_configure(repository = "@nixpkgs")

load("@rules_sh//sh:posix.bzl", "sh_posix_configure")

sh_posix_configure()

# go toolchain test

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "b27e55d2dcc9e6020e17614ae6e0374818a3e3ce6f2024036e688ada24110444",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.21.0/rules_go-v0.21.0.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.21.0/rules_go-v0.21.0.tar.gz",
    ],
)

load(
    "//nixpkgs:toolchains/go.bzl",
    "nixpkgs_go_configure"
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")

go_rules_dependencies()

go_register_toolchains()
