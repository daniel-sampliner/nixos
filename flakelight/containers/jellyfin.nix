# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  lib,
  nix2container,
  writers,

  curl-healthchecker,
  jellyfin,
}:
nix2container.buildImage {
  name = jellyfin.pname;
  tag = jellyfin.version;

  copyToRoot = [
    dockerTools.fakeNss
    dockerTools.caCertificates

    (buildEnv {
      name = "root";
      paths = [
        curl-healthchecker
        jellyfin

        (writers.writeExecline { } "/bin/healthcheck" ''
          curl -qsSf http://localhost:8096/health
        '')
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config =
    let
      vols = [
        "cache"
        "config"
        "data"
        "log"
      ];
    in
    {
      Entrypoint = [ "jellyfin" ];
      Env = builtins.map (v: "JELLYFIN_${lib.toUpper v}_DIR=/${v}") vols;
      ExposedPorts = {
        "8096/tcp" = { };
        "8920/tcp" = { };
        "7359/udp" = { };
      };
      Healthcheck.Test = [
        "CMD"
        "healthcheck"
      ];
      Volumes = lib.pipe vols [
        (builtins.map (v: lib.nameValuePair v { }))
        builtins.listToAttrs
      ];
    };
}
