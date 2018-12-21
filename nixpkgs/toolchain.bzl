load(":toolchains.bzl", "NIX_TOOLCHAINS")
load(":nixpkgs.bzl", "execute_or_fail")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

DEFAULT_VERSION = "2.1.3"

all_nix_exes = [ "nix", "nix-build", "nix-shell", "nix-instantiate", "nix-store" ]

def _nix_install_downloaded_impl(repository_ctx):
    repository_ctx.file("BUILD", content = """
package(default_visibility = ["//visibility:public"])

exports_files({all_nix_exes} + ["nix-user-chroot", "nix-store-path"])
                        """.format(all_nix_exes = all_nix_exes))
    nix_store_path = repository_ctx.attr.nix_store_path
    execute_or_fail(
        repository_ctx,
        [repository_ctx.path(Label("@io_tweag_rules_nixpkgs//nixpkgs:setup_nix.sh")),
         repository_ctx.path(repository_ctx.attr.nix_user_chroot_src),
         repository_ctx.path(repository_ctx.attr.nix_installer),
         nix_store_path,
        ],
    )

nix_install_downloaded = repository_rule(
    implementation = _nix_install_downloaded_impl,
    attrs = {
        "toolchains": attr.string_list_dict(),
        "nix_installer": attr.label(
            allow_single_file = True,
            ),
        "nix_user_chroot_src": attr.label(
            allow_single_file = True,
            ),
        "nix_store_path": attr.string(mandatory = True),
    },
)

def _download_nix_impl(repository_ctx):
    repository_ctx.file("BUILD")
    host = _host_platform(repository_ctx)
    (filename, prefix, sha256) = repository_ctx.attr.toolchains[host]
    repository_ctx.download_and_extract(
        url = [
            url.format(filename = filename, version = repository_ctx.attr.version)
            for url in repository_ctx.attr.urls
        ],
        sha256 = sha256,
    )
    repository_ctx.symlink(prefix, "nix")

_download_nix = repository_rule(
    _download_nix_impl,
    attrs = {
        "toolchains": attr.string_list_dict(),
        "version": attr.string(mandatory = True),
        "urls": attr.string_list(),
    },
)

def nix_download_toolchain(
    name,
    version,
    toolchains,
    urls = ["https://nixos.org/releases/nix/nix-{version}/{filename}"],
    **kwargs
    ):
    _download_nix(
        name = name + "-src",
        version = version,
        toolchains = toolchains,
        urls = urls,
    )
    http_archive(
        name = name + "_nix_user_chroot",
        urls = ["https://github.com/lethalman/nix-user-chroot/archive/809dda7f0a370e069b6bb9d818abebb059806675.tar.gz"],
        strip_prefix = "nix-user-chroot-809dda7f0a370e069b6bb9d818abebb059806675",
        build_file_content = """
    package(default_visibility = ["//visibility:public"])
"""
    )

    nix_install_downloaded(
        name = name,
        nix_installer = "@" + name + "-src" + "//:nix/install",
        nix_user_chroot_src = "@" + name + "_nix_user_chroot" + "//:main.c",
        **kwargs
    )

def _nix_host_toolchain_impl(repository_ctx):
    repository_ctx.file("BUILD", content = """
package(default_visibility = ["//visibility:public"])

exports_files({all_nix_exes})
                        """.format(all_nix_exes = all_nix_exes))
    for exe_name in all_nix_exes:
        exe_fullpath = repository_ctx.which(exe_name)
        if exe_fullpath == None:
            fail("Could not find the `{}` executable in PATH. See: https://nixos.org/nix/".format(exe_name))
        else:
            repository_ctx.symlink(repository_ctx.which(exe_name), exe_name)

nix_host_toolchain = repository_rule(
    implementation = _nix_host_toolchain_impl,
)

def nix_register_toolchains(version = None, nix_store_path = "~/.cache/nix-store"):
    if "nix" not in native.existing_rules():
        if version in NIX_TOOLCHAINS:
            nix_download_toolchain(
                name = "nix",
                version = version,
                toolchains = NIX_TOOLCHAINS[version],
                nix_store_path = nix_store_path,
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
