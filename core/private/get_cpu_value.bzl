
# see https://github.com/tweag/rules_nixpkgs/pull/613
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L225
def get_cpu_value(repository_ctx):
    """Compute the cpu_value based on the OS name. Doesn't %-escape the result!

    Args:
      repository_ctx: The repository context.
    Returns:
      One of (darwin, freebsd, x64_windows, ppc, s390x, arm, aarch64, k8, piii)
    """
    os_name = repository_ctx.os.name
    arch = repository_ctx.os.arch
    if os_name.startswith("mac os"):
        # Check if we are on x86_64 or arm64 and return the corresponding cpu value.
        return "darwin_" + ("arm64" if arch == "aarch64" else "x86_64")
    if os_name.find("freebsd") != -1:
        return "freebsd"
    if os_name.find("openbsd") != -1:
        return "openbsd"
    if os_name.find("windows") != -1:
        if arch == "aarch64":
            return "arm64_windows"
        else:
            return "x64_windows"

    if arch in ["power", "ppc64le", "ppc", "ppc64"]:
        return "ppc"
    if arch in ["s390x"]:
        return "s390x"
    if arch in ["mips64"]:
        return "mips64"
    if arch in ["riscv64"]:
        return "riscv64"
    if arch in ["arm", "armv7l"]:
        return "arm"
    if arch in ["aarch64"]:
        return "aarch64"
    return "k8" if arch in ["amd64", "x86_64", "x64"] else "piii"
