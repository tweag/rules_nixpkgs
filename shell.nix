{ pkgs ? import ./nixpkgs.nix {} }:

with pkgs;

let bazelShell = import ./bazel-shell.nix pkgs; in

let
  some_output =
    runCommand "some-output" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      mkdir -p $out/{bin,include/mylib}
      touch $out/hi-i-exist
      touch $out/hi-i-exist-too
      touch $out/bin/im-a-binary
      touch $out/include/mylib/im-a-header.h
      touch $out/include/mylib/im-also-a-header.h
    '';
in

bazelShell {
  buildInputs = [
    bazel
    gcc
    python2
  ];

  BAZEL_PYTHON="${python2}/bin/python";

  bazelRepositories = {
    hello = { path = hello; };
    output_filegroup_manual_test = {
      path = some_output;
      build_file_content = ''
        package(default_visibility = [ "//visibility:public" ])
        filegroup(
            name = "manual-filegroup",
            srcs = glob(["hi-i-exist", "hi-i-exist-too", "bin/*"]),
        )
      '';
    };
  };

  buildImage = true;
}
