# Bazel remote execution using `rules_nixpkgs`

During a Bazel build with `rules_nixpkgs`, a series of Nix paths will be created on the local
machine, which are then referenced by Bazel either directly or indirectly. The challenge with remote
execution is to ensure that the executors have those Nix store paths available.

To accomplish this `rules_nixpkgs` will copy those paths, through SSH, to a remote Nix server. Then
the paths can be made available to remote executors through a read-only NFS mount.

## Steps

### Setup the Nix server

The first step would be to setup a Nix server. Although we base the following instructions on a
Debian/Ubuntu system, most Linux distributions should work.

1. Install nix
2. Install the NFS server package
```bash
sudo apt-get update
sudo apt-get install nfs-kernel-server nfs-common
```
3. Edit the NFS server's export file (`/etc/exports`)

The following line assumes an internal private CIDR where the mount can be used (`10.0.0.0/16`). You
can adjust according to your setup.

```conf
/nix/store 10.0.0.0/16(ro,sync,no_subtree_check)
```
4. Start the NFS server
```bash
sudo systemctl start nfs-kernel-server
```

### Setup the executors

This step involves mounting the exported file share from the Nix server, allowing the executors to
access the current state of the Nix store. The specific procedures may differ based on your executor
type.

Below are examples for various configurations:

### VM server

1. Install the nfs packages
```bash
sudo apt-get install nfs-common
```
2. Mount the file share

For this we'll need an entry like the following in the `/etc/fstab` file.
```conf
host_ip:/nix/store /nix/store  nfs ro,nfsvers=3 0 0
```

### [BuildBarn](https://github.com/buildbarn) on Kubernetes

Buildbarn provides Kubernetes manifests that you can use to deploy an executor. In order to make it
compatible with the `rules_nixpkgs` we'll need to mount the NFS share. Luckily this is supported
already on Kubernetes.

1. Fetch the Buildbarn manifests from https://github.com/buildbarn/bb-deployments/tree/master/kubernetes

2. Adjust the worker manifest.

Update the `Deployment` spec file of the
[worker](https://github.com/buildbarn/bb-deployments/blob/d142377ce90d48407f01ca67a7707d958de38936/kubernetes/worker-ubuntu22-04.yaml)
to include the NFS share mount on the `runner` container:

```yaml
...
spec:
  template:
    spec:
      containers:
        ...
        name: runner
        volumeMounts:
        ...
        - name: nfs-vol
          mountPath: /nix/store
      volumes:
      - name: nfs-vol
        nfs:
          server: 10.0.0.1 # Replace with the NFS server IP
          readOnly: true
          path: /nix/store
        ...
```

### Configure `rules_nixpkgs` for remote execution

The final step is to configure our Bazel project to use the Nix server and remote execution.

1. Enable copying of Nix paths to the remote server.

This can be done by setting the `BAZEL_NIX_REMOTE` environment variable. This should be the name of
an entry in the [SSH config](https://www.ssh.com/academy/ssh/config) file where all the
authentication details are provided.

```
$ cat $HOME/.ssh/config

Host nix-server
  Hostname 10.0.0.1
  IdentityFile ~/.ssh/nix-server
  Port 2222
  User nix-user

export BAZEL_NIX_REMOTE=nix-server
```

2. Configure remote execution.

We can't give exact instructions for this step because it depends on your specific setup and the executors
or third party service you're using.

Overall this should not affect the way `rules_nixpkgs` works once the Nix paths are available on the
executors.

Example config for Buildbarn:

```conf
build --remote_timeout=3600
build --remote_executor=grpc://<REMOTE_API_ADDR>:<REMOTE_API_PORT>
```

You can use one of the
[examples](https://github.com/tweag/rules_nixpkgs/tree/master/examples/toolchains) to test this
setup.
