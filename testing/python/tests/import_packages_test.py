import sys, pprint
print("python path = ", end="")
pprint.pprint(sys.path)

import flask
print("flask version = ", flask.__version__)

# Also test that click is available.
# nixpkgs_python_repository should provide all the dependencies of requested
# packages. Click is just a random dependency of flask.
import click
print("click version = ", click.__version__)
