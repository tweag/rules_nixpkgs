import sys
import os

executable_path = os.path.realpath(sys.executable)
interpreter_path = os.path.realpath(sys.argv[1])

print("executable_path = " + executable_path)
print("interpreter_path = " + interpreter_path)

if executable_path != interpreter_path:
    sys.stderr.write("sys.executable different to interpreter target")
    sys.exit(1)
