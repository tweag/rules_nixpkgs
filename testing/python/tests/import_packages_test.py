import cffi
print("cffi version = ", cffi.__version__)

import pandas
print("pandas version = ", pandas.__version__)

# Also test that numpy is available.
# nixpkgs_python_repository should provide the dependencies closure.
import numpy
print("numpy version = ", numpy.__version__)
