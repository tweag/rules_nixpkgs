with import <nixpkgs> { config = {}; overlays = []; };

{ attribute_path ? null
, nix_expr ? null
}:

let
  darwinCC =
    # Work around https://github.com/NixOS/nixpkgs/issues/42059.
    # See also https://github.com/NixOS/nixpkgs/pull/41589.
    with darwin.apple_sdk.frameworks;
    runCommand "bazel-nixpkgs-cc-wrapper"
    {
      buildInputs = [ stdenv.cc makeWrapper ];
    }
    ''
      mkdir -p $out/bin

      for i in ${stdenv.cc}/bin/*; do
        ln -sf $i $out/bin
      done

      # Override cc
      rm -f $out/bin/cc $out/bin/clang $out/bin/clang++
      makeWrapper ${stdenv.cc}/bin/cc $out/bin/cc --add-flags \
        "-isystem ${llvmPackages.libcxx}/include/c++/v1 \
        -F${CoreFoundation}/Library/Frameworks \
        -F${CoreServices}/Library/Frameworks \
        -F${Security}/Library/Frameworks \
        -F${Foundation}/Library/Frameworks \
        -L${libcxx}/lib \
        -L${darwin.libobjc}/lib"
    '';
  cc =
    if isNull nix_expr then
      buildEnv {
        name = "bazel-nixpkgs-cc";
        # XXX: `gcov` is missing in `/bin`.
        #   It exists in `stdenv.cc.cc` but that collides with `stdenv.cc`.
        paths =
          if stdenv.isDarwin then
            [ (overrideCC stdenv darwinCC).cc darwin.binutils ]
          else
            [ stdenv.cc binutils ];
        pathsToLink = [ "/bin" ];
      }
    else if isNull attribute_path then
      nix_expr
    else
      lib.attrByPath (lib.splitString "." attribute_path) null nix_expr
  ;
in
  runCommand "bazel-nixpkgs-cc-toolchain"
    { executable = false;
      # Pointless to do this on a remote machine.
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      # This constructs the substitutions for
      # `@bazel_tools//tools/cpp:BUILD.tpl` following the example of
      # `@bazel_tools//tools/cpp:unix_cc_configure.bzl` as of Bazel v2.1.0 git
      # revision 0f4c498a270f05b3896d57055b6489e824821eda.

      # Determine toolchain tool paths.
      #
      # If a tool is not available then we use `bin/false` as a stand-in.
      declare -A TOOLS=( [ar]=ar [cpp]=cpp [dwp]=dwp [gcc]=cc [gcov]=gcov [ld]=ld [nm]=nm [objcopy]=objcopy [objdump]=objdump [strip]=strip )
      TOOL_NAMES=(''${!TOOLS[@]})
      declare -A TOOL_PATHS=()
      for tool_name in ''${!TOOLS[@]}; do
        tool_path=${cc}/bin/''${TOOLS[$tool_name]}
        if [[ -x $tool_path ]]; then
          TOOL_PATHS[$tool_name]=$tool_path
        else
          TOOL_PATHS[$tool_name]=${coreutils}/bin/false
        fi
      done
      cc=''${TOOL_PATHS[gcc]}

      # Check whether a flag is supported by the compiler.
      #
      # The logic checks whether the flag causes an error message that contains
      # the flag (or a pattern) verbatim. The assumption is that this will be a
      # message of the kind `unknown argument: XYZ`. This logic is copied and
      # adapted to bash from `@bazel_tools//tools/cpp:unix_cc_configure.bzl`.
      is_compiler_option_supported() {
        local option="$1"
        local pattern="''${2-$1}"
        { $cc "$option" -o /dev/null -c -x c++ - <<<"int main() {}" 2>&1 1>/dev/null || true; } \
          | grep -qe "$pattern" && return 1 || return 0
      }
      is_linker_option_supported() {
        local option="$1"
        local pattern="''${2-$1}"
        { $cc "$option" -o /dev/null -x c++ - <<<"int main() {}" 2>&1 1>/dev/null || true; } \
          | grep -qe "$pattern" && return 1 || return 0
      }
      add_compiler_option_if_supported() {
        if is_compiler_option_supported "$@"; then
          echo "$1"
        fi
      }
      add_linker_option_if_supported() {
        if is_linker_option_supported "$@"; then
          echo "$1"
        fi
      }

      # Determine default include directories.
      #
      # This is copied and adapted to bash from
      # `@bazel_tools//tools/cpp:unix_cc_configure.bzl`.
      IFS=$'\n'
      include_dirs_for() {
        $cc -E -x "$1" - -v "''${@:2}" 2>&1 \
          | sed -e '1,/^#include <...>/d;/^[^ ]/,$d;s/^ *//' -e 's: (framework directory)::g' \
          | tr '\n' '\0' \
          | xargs -0 realpath -ms
      }
      CXX_BUILTIN_INCLUDE_DIRECTORIES=($({
        include_dirs_for c
        include_dirs_for c++
        if is_compiler_option_supported -fno-canonical-system-headers; then
          include_dirs_for c -fno-canonical-system-headers
          include_dirs_for c++ -std=c++0x -fno-canonical-system-headers
        elif is_compiler_option_supported -no-canonical-prefixes; then
          include_dirs_for c -no-canonical-prefixes
          include_dirs_for c++ -std=c++0x -no-canonical-prefixes
        fi
      } 2>&1 | sort -u))
      unset IFS

      # Determine list of supported compiler and linker flags.
      #
      # This is copied and adapted to bash from
      # `@bazel_tools//tools/cpp:unix_cc_configure.bzl`.
      COMPILER_FLAGS=(
        # Security hardening requires optimization.
        # We need to undef it as some distributions now have it enabled by default.
        -U_FORTIFY_SOURCE
        -fstack-protector
        # All warnings are enabled. Maybe enable -Werror as well?
        -Wall
        $(
          # Enable a few more warnings that aren't part of -Wall.
          add_compiler_option_if_supported -Wthread-safety
          add_compiler_option_if_supported -Wself-assign
          # Disable problematic warnings.
          add_compiler_option_if_supported -Wunused-but-set-parameter
          # has false positives
          add_compiler_option_if_supported -Wno-free-nonheap-object
          # Enable coloring even if there's no attached terminal. Bazel removes the
          # escape sequences if --nocolor is specified.
          add_compiler_option_if_supported -fcolor-diagnostics
        )
        # Keep stack frames for debugging, even in opt mode.
        -fno-omit-frame-pointer
      )
      CXX_FLAGS=(-std=c++0x)
      LINK_FLAGS=(
        $(
          if [[ -x ${cc}/bin/ld.gold ]]; then echo -fuse-ld=gold; fi
          add_linker_option_if_supported -Wl,-no-as-needed -no-as-needed
          add_linker_option_if_supported -Wl,-z,relro,-z,now -z
        )
        ${
          if stdenv.isDarwin
          then "-undefined dynamic_lookup -headerpad_max_install_names"
          else "-B${cc}/bin"
        }
        $(
          # Have gcc return the exit code from ld.
          add_compiler_option_if_supported -pass-exit-codes
        )
        -lstdc++
        -lm
      )
      LINK_LIBS=()
      OPT_COMPILE_FLAGS=(
        # No debug symbols.
        # Maybe we should enable https://gcc.gnu.org/wiki/DebugFission for opt or
        # even generally? However, that can't happen here, as it requires special
        # handling in Bazel.
        -g0

        # Conservative choice for -O
        # -O3 can increase binary size and even slow down the resulting binaries.
        # Profile first and / or use FDO if you need better performance than this.
        -O2

        # Security hardening on by default.
        # Conservative choice; -D_FORTIFY_SOURCE=2 may be unsafe in some cases.
        -D_FORTIFY_SOURCE=1

        # Disable assertions
        -DNDEBUG

        # Removal of unused code and data at link time (can this increase binary
        # size in some cases?).
        -ffunction-sections
        -fdata-sections
      )
      OPT_LINK_FLAGS=(
        ${
          if stdenv.isDarwin
          then ""
          else "$(add_linker_option_if_supported -Wl,--gc-sections -gc-sections)"
        }
      )
      UNFILTERED_COMPILE_FLAGS=(
        $(
          if is_compiler_option_supported -fno-canonical-system-headers; then
            echo -fno-canonical-system-headers
          elif is_compiler_option_supported -no-canonical-prefixes; then
            echo -no-canonical-prefixes
          fi
        )
        # Make C++ compilation deterministic. Use linkstamping instead of these
        # compiler symbols.
        -Wno-builtin-macro-redefined
        -D__DATE__=\\\"redacted\\\"
        -D__TIMESTAMP__=\\\"redacted\\\"
        -D__TIME__=\\\"redacted\\\"
      )
      DBG_COMPILE_FLAGS=(-g)
      COVERAGE_COMPILE_FLAGS=(
        ${
          if stdenv.isDarwin then
            "-fprofile-instr-generate -fcoverage-mapping"
          else
            "--coverage"
        }
      )
      COVERAGE_LINK_FLAGS=(
        ${
          if stdenv.isDarwin then
            "-fprofile-instr-generate"
          else
            "--coverage"
        }
      )
      SUPPORTS_START_END_LIB=(
        $(
          if [[ -x ${cc}/bin/ld.gold ]]; then echo True; else echo False; fi
        )
      )
      IS_CLANG=(
        $(
          ${cc}/bin/cc -v 2>&1 | grep -q clang && echo True || echo False
        )
      )

      # Write CC_TOOLCHAIN_INFO
      #
      # Each line has the following shape:
      #   <key>:<value1>:<value2>:...
      # or
      #   <key>
      # I.e. each line is a colon-separated list of the key and the values.
      mkdir -p $out
      write_info() {
        local -n flags=$1
        local output=( "$1" "''${flags[@]}" )
        IFS=:
        echo "''${output[*]}" >>$out/CC_TOOLCHAIN_INFO
        unset IFS
      }
      write_info TOOL_NAMES
      write_info TOOL_PATHS
      write_info CXX_BUILTIN_INCLUDE_DIRECTORIES
      write_info COMPILER_FLAGS
      write_info CXX_FLAGS
      write_info LINK_FLAGS
      write_info LINK_LIBS
      write_info OPT_COMPILE_FLAGS
      write_info OPT_LINK_FLAGS
      write_info UNFILTERED_COMPILE_FLAGS
      write_info DBG_COMPILE_FLAGS
      write_info COVERAGE_COMPILE_FLAGS
      write_info COVERAGE_LINK_FLAGS
      write_info SUPPORTS_START_END_LIB
      write_info IS_CLANG
    ''
