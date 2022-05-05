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

