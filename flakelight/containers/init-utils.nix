# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  lib,
  nix2container,
  runCommandLocal,

  coreutils,
  dash,
  execline,
  sops,
}:
nix2container.buildImage {
  name = "init-utils";
  tag = "0.0.1";

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        coreutils
        dash
        execline
        sops

        (runCommandLocal "dashSymlink" { } ''
          mkdir -p $out/bin
          ln -sf ${lib.getExe dash} $out/bin/sh
        '')
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Entrypoint = [
      "/bin/sh"
      "-c"
    ];
  };
}