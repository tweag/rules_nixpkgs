# bazel-nix-python-container

An example for a minimal Python flask app running in a Nix-based, Bazel-built, Docker container.
Based on https://github.com/jvolkman/bazel-nix-example. This step-by-step guide below and the
dependency on flask have been added.

## Requirements

The Nix package manager needs to be installed.
Docker is not a requirement for building the container.
However, if you want to run the container we are building, you need Docker of course.

----

## Step 1: The minimal Python flask app:

Create a file `hello.py` with the following content:

```
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "Hello, World!"

app.run(host='0.0.0.0', port=5000)
```

Run it in a nix-shell:
```
nix-shell --pure -p 'python39.withPackages (p: [ p.flask ])' --command 'python3 hello.py'
```

Expect something like this as output:
```
 * Serving Flask app "hello" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
```

----

## Step 2: Nix-Environment with bazel

We're using Nix 22.05 (stable at the time of writing) and Bazel version 5, so
create a file `shell.nix` wit the following content:

```
{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.05.tar.gz") {} }:

pkgs.mkShellNoCC {
    nativeBuildInputs = [
       pkgs.bazel_5
    ];
}
```

Verify by typing:

```
nix-shell --pure --command 'bazel --version'
```

You get something like

```
bazel 5.1.1- (@non-git)
```

---

## Step 3: Bazel-Environment using Nix


### Setup the workspace

Create the `WORKSPACE` file with the following content:

```
workspace(name = "bazel-nix-python-container")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

######################
# Tweag Nix Support
######################
http_archive(
    name = "io_tweag_rules_nixpkgs",
    sha256 = "7aee35c95251c1751e765f7da09c3bb096d41e6d6dca3c72544781a5573be4aa",
    strip_prefix = "rules_nixpkgs-0.8.0",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/v0.8.0.tar.gz"],
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()

# Define nixpkgs version 22.05
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository")
nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "22.05",
    sha256 = "0f8c25433a6611fa5664797cd049c80faefec91575718794c701f3b033f2db01",
)

# Configure python
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_python_configure")
nixpkgs_python_configure(
    python3_attribute_path = "python39.withPackages(ps: [ ps.flask ])",
    repository = "@nixpkgs",
)

#########
# Python
#########
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_python",
    sha256 = "cdf6b84084aad8f10bf20b46b77cb48d83c319ebe6458a18e9d2cebf57807cdd",
    strip_prefix = "rules_python-0.8.1",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.8.1.tar.gz",
)
```


### create `.bazelrc` with nix config

Put the following into the `.bazelrc` file:
```
build:nix --host_platform=@io_tweag_rules_nixpkgs//nixpkgs/platforms:host
```

### Create the BUILD file

This needs to go into the `BUILD` file:
```
py_binary(
    name = "hello",
    srcs = ["hello.py"],
    main = "hello.py",
)
```


### Run

To run our python app in bazel, type:
```
nix-shell --command 'bazel run --config=nix :hello'
```

After setting everything up, bazel should output something like this:
```
INFO: Analyzed target //:hello (22 packages loaded, 96 targets configured).
INFO: Found 1 target...
Target //:hello up-to-date:
  bazel-bin/hello
INFO: Elapsed time: 37.590s, Critical Path: 0.03s
INFO: 4 processes: 4 internal.
INFO: Build completed successfully, 4 total actions
INFO: Build completed successfully, 4 total actions
 * Serving Flask app 'hello' (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on all addresses.
   WARNING: This is a development server. Do not use it in a production deployment.
 * Running on http://172.21.24.71:5000/ (Press CTRL+C to quit)
```

----

## Step 4: Create a Docker container

### Create Docker image with Nix

We are generating an image with python3 including the flask module.
Create a file with the name `python39_base_image.nix` and the following content:
```
with import <nixpkgs> {};

let
  dockerEtc = runCommand "docker-etc" {} ''
    mkdir -p $out/etc/pam.d

    echo "root:x:0:0::/root:/bin/bash" > $out/etc/passwd
    echo "root:!x:::::::" > $out/etc/shadow
    echo "root:x:0:" > $out/etc/group
  '';

  pythonBase = dockerTools.buildLayeredImage {
    name = "python39-base-image-unwrapped";
    created = "now";
    maxLayers = 2;
    contents = [
      bashInteractive
      coreutils

      # Specify your Python version and packages here:
      (python39.withPackages( p: [p.flask] ))

      stdenv.cc.cc.lib
      iana-etc
      cacert
      dockerEtc
    ];
    extraCommands = ''
      mkdir -p root
      mkdir -p usr/bin
      ln -s /bin/env usr/bin/env
      cat <<-"EOF" > "usr/bin/python3"
#!/bin/sh
export LD_LIBRARY_PATH="/lib64:/lib"
exec -a "$0" "/bin/python3" "$@"
EOF
      chmod +x usr/bin/python3
      ln -s /usr/bin/python3 usr/bin/python
    '';
  };
  # rules_nixpkgs require the nix output to be a directory,
  # so we create one in which we put the image we've just created
in runCommand "python39-base-image" { } ''
  mkdir -p $out
  gunzip -c ${pythonBase} > $out/image
''
```

Independent of Bazel we can now build a Docker container with nix:
```
nix-build python39_base_image.nix
```

If everything went well, the last line of the `nix-build` output should give you the location of the image
```
/nix/store/gnd2dl80mwrbnzk77h43fl07cb694vcx-python38-base-image
```

We can now load freshly baked image (Docker installation required):
```
docker load -i /nix/store/gnd2dl80mwrbnzk77h43fl07cb694vcx-python38-base-image/image
```

The `docker load` command gives us the name of the image as output:
```
Loaded image: python39-base-image-unwrapped:ypv5lns0sbbf0jgkkjsyxgxxlphnaaaa
```

Let's run `hello.py` in it:
```
docker run -v $PWD/hello.py:/hello.py:ro --rm -it python39-base-image-unwrapped:ypv5lns0sbbf0jgkkjsyxgxxlphnaaaa python /hello.py
```
Which should show us the familiar
```
 * Serving Flask app "hello" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: off
```

### Add Docker support to the work space

We need to append the following to the `WORKSPACE` file:
```
#########
# Docker
#########
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "27d53c1d646fc9537a70427ad7b034734d08a9c38924cc6357cc973fed300820",
    strip_prefix = "rules_docker-0.24.0",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.24.0/rules_docker-v0.24.0.tar.gz"],
)

load("@io_bazel_rules_docker//repositories:repositories.bzl", container_repositories = "repositories",)
container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")
container_deps()

load("@io_bazel_rules_docker//repositories:py_repositories.bzl", "py_deps")
py_deps()

load("@io_bazel_rules_docker//python3:image.bzl", py3_image_repos = "repositories")
py3_image_repos()
```

### Build Docker image with Nix via Bazel

Let's append the follwowing to the `WORKSPACE` file in order to have Bazel build our Docker image with Nix:
```
nixpkgs_package(
    name = "raw_python39_base_image",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
exports_files(["image"])
    """,
    nix_file = "//:python39_base_image.nix",
    repository = "@nixpkgs//:default.nix",
)

load("@io_bazel_rules_docker//container:container.bzl", "container_load" )
container_load(name = "python39_base_image", file = "@raw_python39_base_image//:image")
```

Now in our `BUILD` append the following to tell Bazel to create another Docker image, based on the `python39_base_image`:
```
load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")

package(default_visibility = ["//visibility:public"])

py3_image(
    name = "hello_image",
    srcs = [ "hello.py" ],
    base = "@python39_base_image//image",
    main = "hello.py",

    # Currently needs to be built on Linux.
    target_compatible_with = [
        "@platforms//os:linux",
    ],
)
```

Finally, build the image including our `hello.py`:
```
nix-shell --command 'bazel build --config=nix :hello_image'
```

And run it:
```
nix-shell --command 'bazel run --config=nix :hello_image'
```
