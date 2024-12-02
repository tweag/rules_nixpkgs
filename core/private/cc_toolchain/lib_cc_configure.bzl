# pylint: disable=g-bad-file-header
# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Base library for configuring the C++ toolchain.

This file contains parts of `@bazel_tools//tools/cpp:lib_cc_configure.bzl` that are needed by rules_nixpkgs and that were removed from Bazel.
"""


load("@bazel_skylib//lib:versions.bzl", "versions")

# symbol once lived in @bazel_tools and is now private within rules_cc
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L108-L112
def auto_configure_fail(msg):
    """Output failure message when auto configuration fails."""
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n%sAuto-Configuration Error:%s %s\n" % (red, no_color, msg))

# symbol once lived in @bazel_tools and is now private within rules_cc
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L114-L120
def auto_configure_warning(msg):
    """Output warning message during auto configuration."""
    yellow = "\033[1;33m"
    no_color = "\033[0m"

    # buildifier: disable=print
    print("\n%sAuto-Configuration Warning:%s %s\n" % (yellow, no_color, msg))

# symbol once lived in @bazel_tools and is now private within rules_cc
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L122-L141
def get_env_var(repository_ctx, name, default = None, enable_warning = True):
    """Find an environment variable in system path. Doesn't %-escape the value!

    Args:
      repository_ctx: The repository context.
      name: Name of the environment variable.
      default: Default value to be used when such environment variable is not present.
      enable_warning: Show warning if the variable is not present.
    Returns:
      value of the environment variable or default.
    """

    if name in repository_ctx.os.environ:
        return repository_ctx.os.environ[name]
    if default != None:
        if enable_warning:
            auto_configure_warning("'%s' environment variable is not set, using '%s' as default" % (name, default))
        return default
    auto_configure_fail("'%s' environment variable is not set" % name)
    return None

# symbol once lived in @bazel_tools and is now private within rules_cc
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L271-L275
def get_starlark_list(values):
    """Convert a list of string into a string that can be passed to a rule attribute."""
    if not values:
        return ""
    return "\"" + "\",\n    \"".join(values) + "\""

# symbol once lived in @bazel_tools and is now private within rules_cc
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
        if arch == "aarch64":
            return "darwin_arm64"

        # NOTE(cb) for backward compatibility return "darwin" for Bazel < 7 on x86_64
        if versions.is_at_least("7.0.0", versions.get()):
            return "darwin_x86_64"
        else:
            return "darwin"

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

# symbol once lived in @bazel_tools and is now private within rules_cc
# taken from https://github.com/bazelbuild/rules_cc/blob/8395ec0172270f3bf92cd7b06c9b5b3f1f679e88/cc/private/toolchain/lib_cc_configure.bzl#L282-L303
def write_builtin_include_directory_paths(repository_ctx, cc, directories, file_suffix = ""):
    """Generate output file named 'builtin_include_directory_paths' in the root of the repository."""
    if get_env_var(repository_ctx, "BAZEL_IGNORE_SYSTEM_HEADERS_VERSIONS", "0", False) == "1":
        repository_ctx.file(
            "builtin_include_directory_paths" + file_suffix,
            """This file is generated by cc_configure and normally contains builtin include directories
that C++ compiler reported. But because BAZEL_IGNORE_SYSTEM_HEADERS_VERSIONS was set to 1,
header include directory paths are intentionally not put there.
""",
        )
    else:
        repository_ctx.file(
            "builtin_include_directory_paths" + file_suffix,
            """This file is generated by cc_configure and contains builtin include directories
that %s reported. This file is a dependency of every compilation action and
changes to it will be reflected in the action cache key. When some of these
paths change, Bazel will make sure to rerun the action, even though none of
declared action inputs or the action commandline changes.

%s
""" % (cc, "\n".join(directories)),
        )
