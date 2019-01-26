nixpkgs:

let
  # Make the given path a concrete file instead of symlink so that we can
  # overwrite it if needed
  unSymLink = path: ''
    test -L ${path} && mv ${path} ${path}.old && cat ${path}.old > ${path} && rm ${path}.old
  '';
  shadowEnv = nixpkgs.runCommand "shadowWithSetup" {} ''
    mkdir -p $out/etc/pam.d
    if [[ ! -f $out/etc/passwd ]]; then
     echo "root:x:0:0::/root:/bin/sh" > $out/etc/passwd
     echo "root:!x:::::::" > $out/etc/shadow
    fi
    if [[ ! -f $out/etc/group ]]; then
     echo "root:x:0:" > $out/etc/group
     echo "root:x::" > $out/etc/gshadow
    fi
    if [[ ! -f $out/etc/pam.d/other ]]; then
     cat > $out/etc/pam.d/other <<EOF
    account sufficient pam_unix.so
    auth sufficient pam_rootok.so
    password requisite pam_unix.so nullok sha512
    session required pam_unix.so
    EOF
    fi
    if [[ ! -f $out/etc/login.defs ]]; then
     touch $out/etc/login.defs
    fi

    mkdir -p $out/bin
    cat <<EOF > $out/bin/groupadd
    #!/bin/sh

    ${unSymLink "/etc/group"}
    ${unSymLink "/etc/gshadow"}

    exec ${nixpkgs.shadow}/bin/groupadd "\$@"
    EOF
    chmod +x $out/bin/groupadd

    cat <<EOF > $out/bin/useradd
    #!/bin/sh

    ${unSymLink "/etc/passwd"}
    ${unSymLink "/etc/shadow"}

    ${nixpkgs.shadow}/bin/useradd "\$@"

    # XXX Big hack: Give the right access to the bazel user
    chmod 755 /nix /nix/store

    EOF
    chmod +x $out/bin/useradd
  '';
  buildRbeImage = buildEnv:
  let
    dockerImage =
      nixpkgs.dockerTools.buildLayeredImage {
      name = "rbe-image";
      tag = "0.0";
      contents = [buildEnv nixpkgs.bash nixpkgs.coreutils shadowEnv];
      # We just need to leave a few extra layers (out of the 128 available) for
      # the small dockerfile used by bazel rbe
      # maxLayers = 120;
      config = {
        Entrypoint = "${buildEnv}/bin/entrypoint";
        Cwd = buildEnv;
      };
    };
    imageInSubfolder = nixpkgs.runCommand "rbe-image-folder" {} ''
      mkdir -p $out
      ln -s ${dockerImage} $out/image.tar.gz
    '';
  in
  {
    path = imageInSubfolder;
    build_file_content = ''
      exports_files(["image.tar.gz"])
    '';
  };
  optionalBazelValue = maybeNull:
    if maybeNull == null then "None" else ''"""${maybeNull}"""'';
  nix2bzl = { ... }@packageConfigs:
    let
      generatedRepos = builtins.concatStringsSep "\n  " (
        builtins.attrValues (
          builtins.mapAttrs (
            repo_name: { path, build_file_content ? null, build_file ? null }:
            let
              actual_build_file =
                if build_file_content == null && build_file == null
                then "@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"
                else build_file;
            in
              ''
            native.new_local_repository(
                name = "${repo_name}",
                path = "${path}",
                build_file_content = ${optionalBazelValue build_file_content},
                build_file = ${optionalBazelValue actual_build_file},
              )
            ''
          )
          packageConfigs
        )
      );
    in
    nixpkgs.writeText "bazel-nix-deps.bzl" ''
      def nix_packages():
        ${generatedRepos}
    '';
  bazelShell = { bazelRepositories ? {}, shellHook ? "", buildImage ? false, ... }@args:
  let
    allArgs = args // {
      bazelRepositories = builtins.toJSON bazelRepositories;
      nobuildPhase = ''
        mkdir -p $out/bin
        cp ${./entrypoint.py} $out/bin/entrypoint
        sed -i "s#env.json#$out/env.json#" $out/bin/entrypoint
        python ${./dump_env.py} > $out/env.json
        patchShebangs $out
      '';
    };
    depsShell = nixpkgs.mkShell allArgs;
    repositoriesWDocker = bazelRepositories //
      (if buildImage then { rbeDockerImage = buildRbeImage depsShell; } else {});
    shellWithDocker = nixpkgs.mkShell (allArgs // {
      shellHook = ''
            ln -fs ${nix2bzl repositoriesWDocker} ./nix-repositories.bzl
      '' + shellHook;
    });
    in
    shellWithDocker;
in
  bazelShell
