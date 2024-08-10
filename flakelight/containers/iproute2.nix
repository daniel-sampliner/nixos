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
  iproute2,
  iptables-legacy,
}:
nix2container.buildImage {
  name = iproute2.pname;
  tag = iproute2.version;

  copyToRoot = buildEnv {
    name = "root";
    paths = [
      coreutils
      dash
      execline

      (iproute2.override { iptables = iptables-legacy; })
      (runCommandLocal "dashSymlink" { } ''
        mkdir -p $out/bin
        ln -sf ${lib.getExe dash} $out/bin/sh
      '')
    ];

    pathsToLink = [ "/bin" ];
  };

  config = {
    Entrypoint = [
      "/bin/sh"
      "-c"
    ];
  };
}
