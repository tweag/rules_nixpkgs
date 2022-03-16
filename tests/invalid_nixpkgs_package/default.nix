{ ... }:
let
  message = import ./message.nix;
  # `COREUTILS-ABS-PATH` is replaced by the absolute path of a static
  # `coreutils` before calling `bazel build`
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
