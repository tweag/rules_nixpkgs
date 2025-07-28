load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    "nixpkgs_flake_package",
    "nixpkgs_git_repository",
    "nixpkgs_http_repository",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

def nixpkgs_repositories(*, bzlmod):
    nixpkgs = "@nixpkgs"
    remote_nixpkgs = "@remote_nixpkgs"
    http_nixpkgs = "@http_nixpkgs"
    file_nixpkgs = "@file_nixpkgs"
    nixpkgs_content = "@nixpkgs_content"
    flakehub_nixpkgs = "@flakehub_nixpkgs"
    if not bzlmod:
        nixpkgs_local_repository(
            name = "nixpkgs",
            nix_file = "//:nixpkgs.nix",
            nix_file_deps = ["//:flake.lock"],
        )

        nixpkgs_git_repository(
            name = "remote_nixpkgs",
            remote = "https://github.com/NixOS/nixpkgs",
            revision = "22.05",
            sha256 = "0f8c25433a6611fa5664797cd049c80faefec91575718794c701f3b033f2db01",
        )

        nixpkgs_http_repository(
            name = "http_nixpkgs",
            url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.05.tar.gz",
            strip_prefix = "nixpkgs-22.05",
            sha256 = "0f8c25433a6611fa5664797cd049c80faefec91575718794c701f3b033f2db01",
        )

        # same as @nixpkgs, only needed for bzlmod tests to distinguish `default` and `file`.
        nixpkgs_local_repository(
            name = "file_nixpkgs",
            nix_file = "//:nixpkgs.nix",
            nix_file_deps = ["//:flake.lock"],
        )

        # same as @nixpkgs but using the `nix_file_content` parameter
        nixpkgs_local_repository(
            name = "nixpkgs_content",
            nix_file_content = "import ./nixpkgs.nix",
            nix_file_deps = [
                "//:nixpkgs.nix",
                "//:flake.lock",
            ],
        )

        nixpkgs_package(
            name = "hello",
            # Deliberately not repository, to test whether repositories works.
            repositories = {"nixpkgs": nixpkgs},
        )

        nixpkgs_package(
            name = "attribute-test",
            attribute_path = "hello",
            repository = nixpkgs,
        )

        nixpkgs_package(
            name = "nixpkgs-git-repository-test",
            attribute_path = "hello",
            repositories = {"nixpkgs": remote_nixpkgs},
        )

        nixpkgs_package(
            name = "nix-file-test",
            attribute_path = "hello",
            nix_file = "//tests:nixpkgs.nix",
            repository = nixpkgs,
        )

        nixpkgs_package(
            name = "nix-file-deps-test",
            nix_file = "//tests:hello.nix",
            nix_file_deps = ["//tests:pkgname.nix"],
            repository = nixpkgs,
        )

        nixpkgs_package(
            name = "expr-test",
            nix_file_content = "let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in pkgs.hello",
            nix_file_deps = ["//:flake.lock"],
            # Deliberately not @nixpkgs, to test whether explict file works.
            repositories = {"nixpkgs": "//:nixpkgs.nix"},
        )

        nixpkgs_package(
            name = "expr-attribute-test",
            attribute_path = "hello",
            nix_file_content = "import <nixpkgs> { config = {}; overlays = []; }",
            repository = nixpkgs,
        )

        nixpkgs_package(
            name = "nixpkgs-http-repository-test",
            attribute_path = "hello",
            repositories = {"nixpkgs": http_nixpkgs},
        )

        nixpkgs_package(
            name = "nixpkgs-file-repository-test",
            nix_file_content = "with import <nixpkgs> {}; hello",
            repositories = {"nixpkgs": file_nixpkgs},
        )

        nixpkgs_package(
            name = "nixpkgs-local-repository-test",
            nix_file_content = "with import <nixpkgs> {}; hello",
            repositories = {"nixpkgs": nixpkgs_content},
        )

        nixpkgs_package(
            name = "relative-imports",
            attribute_path = "hello",
            nix_file = "//tests:relative_imports.nix",
            nix_file_deps = [
                "//:flake.lock",
                "//:nixpkgs.nix",
                "//tests:relative_imports/nixpkgs.nix",
            ],
            repository = nixpkgs,
        )

        nixpkgs_package(
            name = "output-filegroup-test",
            nix_file = "//tests:output.nix",
            repository = nixpkgs,
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
            repository = nixpkgs,
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
            repository = nixpkgs,
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
            "arg_local_file",
            "$(location //tests:location_expansion/test_file)",
            "--arg",
            "arg_external_file",
            './$${"$(location @nixpkgs_location_expansion_test_file//:test_file)"}',
            "--arg",
            "workspace_root",
            "./.",
            "--argstr",
            "argstr_local_file",
            "$(location //tests:location_expansion/test_file)",
            "--argstr",
            "argstr_external_file",
            "$(location @nixpkgs_location_expansion_test_file//:test_file)",
        ],
        repository = remote_nixpkgs,
    )

    # TODO this is currently untested,
    #   see https://github.com/tweag/rules_nixpkgs/issues/318
    # This bazel build @output-derivation-is-a-file//... must fail
    # See https://github.com/tweag/rules_nixpkgs/issues/99 for details
    nixpkgs_package(
        name = "output-derivation-is-a-file",
        attribute_path = "",
        nix_file_content = """let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in pkgs.writeText "foo" "bar" """,
        nix_file_deps = [
            "//:flake.lock",
            "//:nixpkgs.nix",
            "//tests:relative_imports/nixpkgs.nix",
        ],
        repository = nixpkgs,
    )

    nixpkgs_flake_package(
        name = "flake-hello",
        nix_flake_file = "//:flake.nix",
        nix_flake_lock_file = "//:flake.lock",
        package = "hello",
    )

    nixpkgs_flake_package(
        name = "flake-hello-with-build-file",
        nix_flake_file = "//:flake.nix",
        nix_flake_lock_file = "//:flake.lock",
        package = "hello-with-build-file",
    )

    # Test FlakeHub tarball support
    nixpkgs_local_repository(
        name = "flakehub_nixpkgs",
        nix_flake_lock_file = "//:flakehub_test.lock",
    )

    nixpkgs_package(
        name = "flakehub-test",
        attribute_path = "hello",
        repository = flakehub_nixpkgs,
    )
