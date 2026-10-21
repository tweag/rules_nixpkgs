#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    exit 0
fi

library=$1
toolchain_info=$2

ar_path=$(awk -F: '
    $1 == "TOOL_NAMES" {
        for (i = 2; i <= NF; i++) {
            if ($i == "ar") {
                ar_index = i
            }
        }
    }
    $1 == "TOOL_PATHS" && ar_index {
        print $ar_index
        exit
    }
' "$toolchain_info")

if [[ -z "$ar_path" ]]; then
    echo "could not find ar in CC_TOOLCHAIN_INFO" >&2
    exit 1
fi

tool_bindir=${ar_path%/*}
install_name_tool="$tool_bindir/install_name_tool"
install_name_tool_resign="$tool_bindir/install_name_tool_resign"
test_dir=$(mktemp -d "${TEST_TMPDIR:-/tmp}/install-name-tool-signature.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

normal_output="$test_dir/normal.dylib"
resigned_output="$test_dir/resigned.dylib"
cp "$library" "$normal_output"
cp "$library" "$resigned_output"

/usr/bin/codesign -f -s - "$normal_output"
/usr/bin/codesign -f -s - "$resigned_output"
/usr/bin/codesign --verify --verbose=2 "$normal_output"
"$install_name_tool" -change /usr/lib/libSystem.B.dylib /usr/lib/libSystem.1.dylib "$normal_output"
if /usr/bin/codesign --verify --verbose=2 "$normal_output" >/dev/null 2>&1; then
    echo "install_name_tool unexpectedly preserved the code signature" >&2
    exit 1
fi

"$install_name_tool_resign" -change /usr/lib/libSystem.B.dylib /usr/lib/libSystem.1.dylib "$resigned_output"
/usr/bin/codesign --verify --verbose=2 "$resigned_output"