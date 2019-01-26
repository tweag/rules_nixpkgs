#!/usr/bin/env python

import json
import os
import subprocess
import sys

def load_env(raw_env):
    for (var_name, var_value) in json.load(raw_env).items():
        os.environ[var_name] = var_value

def load_env_file(env_file):
    with open(env_file) as f:
        load_env(f)

if __name__ == '__main__':
    load_env_file("env.json")
    subprocess.check_call(sys.argv[1:])
