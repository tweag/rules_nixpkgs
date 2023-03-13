import sys, pprint
print("python path = ", end="")
pprint.pprint(sys.path)

import flask
print("flask version = ", flask.__version__)

# Also test that numpy is available.
# nixpkgs_python_repository should provide the dependencies closure.
import click
print("click version = ", click.__version__)
