load(":toolchains.bzl", "NIX_TOOLCHAINS")
load(":nixpkgs.bzl", "execute_or_fail")

DEFAULT_VERSION = "2.1.3"

def _nix_download_toolchain_impl(repository_ctx):
    nix_store_path = repository_ctx.attr.nix_store_path
    repository_ctx.template(
        "BUILD",
        Label("@io_tweag_rules_nixpkgs//nixpkgs:prebuild_BUILD.pkg"),
        substitutions = {
            "NIX_STORE_PATH": nix_store_path,
            }
        )
    execute_or_fail(
        repository_ctx,
        [repository_ctx.path(Label("@io_tweag_rules_nixpkgs//nixpkgs:setup_nix.sh")),
         repository_ctx.path(repository_ctx.attr.nix_user_chroot_src),
         repository_ctx.path(repository_ctx.attr.nix_installer),
         nix_store_path,
        ],
        quiet = False, # XXX: Remove when debugging is over
    )

nix_download_toolchain = repository_rule(
    implementation = _nix_download_toolchain_impl,
    attrs = {
        "toolchains": attr.string_list_dict(),
        "nix_installer": attr.label(
            allow_single_file = True,
            ),
        "nix_user_chroot_src": attr.label(
            allow_single_file = True,
            ),
        "nix_store_path": attr.string(mandatory = True),
        # "strip_prefix": attr.string(),
        # "version": attr.string(mandatory = True),
        # "urls": attr.string_list(
        #     default = ["https://nixos.org/releases/nix/nix-{version}/{filename}"]
        # ),
    },
)

def _nix_host_toolchain_impl(repository_ctx):
    pass
    # toolchain_info = platform_common.ToolchainInfo(
    #     nix_info = NixInfo(
    #       store_path = None,
    #       nix_build_path = repository_ctx.which("nix-build"),
    #     ),
    # )
    # return [toolchain_info]
    # repository_ctx.file("BUILD")
    # repository_ctx.symlink(repository_ctx.which("nix-build"), "nix-build")

nix_host_toolchain = repository_rule(
    implementation = _nix_host_toolchain_impl,
)

def nix_register_toolchains(version = None):
    if "nix" not in native.existing_rules():
        if version in NIX_TOOLCHAINS:
            nix_download_toolchain(
                name = "nix",
                version = version,
                toolchains = NIX_TOOLCHAINS[version],
            )
        elif version == "host":
            nix_host_toolchain(
                name = "nix"
            )
        else:
            fail("Unknown Nix version {}".format(version))


# Copied from
# https://github.com/bazelbuild/rules_go/blob/master/go/private/sdk.bzl.
def _host_platform(repository_ctx):
    if repository_ctx.os.name == "linux":
        host = "linux_amd64"
        res = repository_ctx.execute(["uname", "-p"])
        if res.return_code == 0:
            uname = res.stdout.strip()
            if uname == "s390x":
                host = "linux_s390x"
            elif uname == "i686":
                host = "linux_386"

        # uname -p is not working on Aarch64 boards
        # or for ppc64le on some distros
        res = repository_ctx.execute(["uname", "-m"])
        if res.return_code == 0:
            uname = res.stdout.strip()
            if uname == "aarch64":
                host = "linux_arm64"
            elif uname == "armv6l":
                host = "linux_arm"
            elif uname == "armv7l":
                host = "linux_arm"
            elif uname == "ppc64le":
                host = "linux_ppc64le"

        # Default to amd64 when uname doesn't return a known value.

    elif repository_ctx.os.name == "mac os x":
        host = "darwin_amd64"
    elif repository_ctx.os.name.startswith("windows"):
        host = "windows_amd64"
    elif repository_ctx.os.name == "freebsd":
        host = "freebsd_amd64"
    else:
        fail("Unsupported operating system: " + repository_ctx.os.name)

    return host
