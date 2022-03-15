{ ... }:
let
  message = import ./message.nix;
  # BUSYBOX-ABS-PATH is replaced by the absolute path of a static
  # busybox before calling the bazel build command
  script = ''
    COREUTILS-ABS-PATH/mkdir -p $out/bin
    echo echo ${message} > $out/bin/hello
    COREUTILS-ABS-PATH/chmod a+x $out/bin/hello
  '';
in
{
  hello = builtins.derivation {
    name = "hello";
    system = builtins.currentSystem;
    builder = "/bin/sh";
    args = [ "-c" script ];
  };
}
