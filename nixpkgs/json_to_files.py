#!/usr/bin/env python2

import json
import os
import os.path
import sys

def mapping_to_files(containing_directory, mappings):
    """Take a ``[String, String]Dict`` and for each ``(name, path)`` kv pair
    write a file ``{containing_directory}/name`` containing ``path``
    """
    for (name, dest_path) in mappings.items():
        with open(os.path.join(containing_directory, name), 'w+') as f:
            f.write(dest_path)

def main():
    dest_dir = sys.argv[1]
    mappings_file = sys.argv[2]
    with open(mappings_file, 'r') as mappings_json:
        mapping_to_files(dest_dir, json.load(mappings_json))

if __name__ == "__main__":
    main()
