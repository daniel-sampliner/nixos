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
  procps,
  s6,
  s6-portable-utils,
  sops,
  wireguard-tools,
}:
let
  my-iproute2 = iproute2.override { iptables = iptables-legacy; };
  my-wireguard-tools = wireguard-tools.override {
    iproute2 = my-iproute2;
    iptables = iptables-legacy;
    procps = procps.override { withSystemd = false; };
  };
in
nix2container.buildImage {
  name = "init-utils";
  tag = "0.0.2";

  copyToRoot = buildEnv {
    name = "root";
    paths = [
      coreutils
      dash
      execline
      s6
      s6-portable-utils
      sops

      my-iproute2
      my-wireguard-tools

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
