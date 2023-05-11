{ stream ? true, tag ? null, nixpkgs ? import <nixpkgs> {} }:
let
  dockerImage = if stream
    then nixpkgs.dockerTools.streamLayeredImage
    else nixpkgs.dockerTools.buildLayeredImage;

  name = %{name};

  contents = [
    %{contents}
  ];

  manifest = nixpkgs.writeTextFile
    { name = "${name}-MANIFEST";
      text = nixpkgs.lib.strings.concatMapStrings (pkg: "${pkg}\n") contents;
      destination = "/MANIFEST";
    };

  usr_bin_env = nixpkgs.runCommand "usr-bin-env" {} ''
    mkdir -p "$out/usr/bin/"
    ln -s "${nixpkgs.coreutils}/bin/env" "$out/usr/bin/"
  '';
in
  dockerImage {
    inherit name tag;

    contents = [
      # Contents get copied to the top-level of the image, so we jus putt
      # a short manifest file here and get all the store paths as dependencies
      manifest

      # Ensure "/usr/bin/env bash" works correctly
      nixpkgs.bash
      nixpkgs.coreutils
      usr_bin_env

      # avoid "commitBuffer: invalid argument (invalid character)" running tests
      nixpkgs.glibcLocales
    ];

    extraCommands = "mkdir -m 0777 tmp";

    config = {
      Cmd = [ "${nixpkgs.bashInteractive}/bin/bash" ];
    };
  }
