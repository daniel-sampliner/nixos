# SPDX-FileCopyrightText: 2024, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dnsmasq,
  ldns,
  nix2container,
  s6-portable-utils,
  stdenv,
  writers,
}:
let
  healthcheck = writers.writeExecline { } "/bin/healthcheck" ''
    backtick -E v { s6-maximumtime 1000 drill -Q CH TXT version.bind }
    if { eltest -n $v }
    s6-echo $v
  '';
in
nix2container.buildImage {
  name = dnsmasq.pname;
  tag = dnsmasq.version;

  copyToRoot = buildEnv {
    name = "root";
    paths = [
      ldns
      s6-portable-utils

      healthcheck

      (dnsmasq.override {
        dbusSupport = false;
        stdenv = stdenv // {
          isLinux = false;
        };
      })
    ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Entrypoint = [ "dnsmasq" ];
    Volumes = {
      "/var/run" = { };
    };
  };
}
