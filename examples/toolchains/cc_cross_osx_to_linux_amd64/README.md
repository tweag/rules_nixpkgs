Linux C++ In Docker, Cross Compiled on MacOS
============================================

Builds a Docker image containing a C++ program cross compiled for Linux, on MacOS.

# Usage

To build the image with Nix, issue the following command:
```
nix-shell --command 'bazel build --config=cross :hello_image_tarball'
```

You can then do load the image into Docker with:
```
docker load -i bazel-bin/hello_image_tarball/tarball.tar
```

And run it as you normally would with Docker.
