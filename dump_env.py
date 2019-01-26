#!/usr/bin/env python

import json
import os
import sys

def env_as_dict(env):
    """
    Convert the given _Environ object (result of ``os.environ``) to a proper
    dict suitable to be dumped as json
    """
    final_dict = {}
    for (key, value) in env.items():
        final_dict[key] = value
    return final_dict

def dump_env(env, dest_channel):
    json.dump(env_as_dict(env), dest_channel)

if __name__ == '__main__':
    dump_env(os.environ, sys.stdout)
