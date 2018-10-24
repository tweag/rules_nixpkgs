#!/bin/sh
# first param is the expected number of files given by `locations`
expected_length="$1"

# rest of the arguments are files
shift
no_of_files=$#

if [ "$no_of_files" -ne "$expected_length" ]; then
    echo "Should have received $expected_length files, but got $no_of_files:"
    for f in "$@"; do
        echo "$f"
    done
    exit 1
fi
