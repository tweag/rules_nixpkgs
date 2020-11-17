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

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

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

# This is the commit introducing a Nix version working in the Bazel
# sandbox
nixpkgs_git_repository(
    name = "remote_nixpkgs_for_nix_unstable",
    remote = "https://github.com/NixOS/nixpkgs",
    revision = "15d1011615d16a8b731adf28e2cfc33481102780",
    sha256 = "8b1161a249d50effea1f240c34a81832a88c8d5d274314ae6225fd78bd62dfb9",
)

nixpkgs_package(
    name = "nix-unstable",
    attribute_path = "nixUnstable",
    repositories = {"nixpkgs": "@remote_nixpkgs_for_nix_unstable"},
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

# This is used to run Nix in a sandboxed Bazel test. See the test
# run-test-invalid-nixpkgs-package.
nixpkgs_package(
    name = "busybox_static",
    attribute_path = "pkgsStatic.busybox",
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

local_repository(
    name = "nixpkgs_location_expansion_test_file",
    path = "tests/location_expansion/test_repo",
)

nixpkgs_package(
    name = "nixpkgs_location_expansion_test",
    build_file_content = "exports_files(glob(['out/**']))",
    nix_file = "//tests:location_expansion.nix",
    nix_file_deps = [
        "//tests:location_expansion/test_file",
        "@nixpkgs_location_expansion_test_file//:test_file",
    ],
    nixopts = [
        "--arg",
        "local_file",
        "$(location //tests:location_expansion/test_file)",
        "--arg",
        "external_file",
        "$(location @nixpkgs_location_expansion_test_file//:test_file)",
    ],
    repository = "@remote_nixpkgs",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_sh",
    sha256 = "83a065ba6469135a35786eb741e17d50f360ca92ab2897857475ab17c0d29931",
    strip_prefix = "rules_sh-0.2.0",
    urls = ["https://github.com/tweag/rules_sh/archive/v0.2.0.tar.gz"],
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
    "nixpkgs_go_configure",
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()
