with import <nixpkgs> { config = {}; overlays = []; };

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
''
