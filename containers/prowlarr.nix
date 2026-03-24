# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  nix2container,
  writers,

  curlMinimal,
  prowlarr,
}:
nix2container.buildImage {
  name = prowlarr.pname;
  tag = prowlarr.version;

  copyToRoot = [
    dockerTools.caCertificates
    dockerTools.fakeNss

    (buildEnv {
      name = "root";
      paths = [
        curlMinimal
        prowlarr

        (writers.writeExecline { } "/bin/healthcheck" ''
          curl -qSsf http://localhost:9696/ping
        '')
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Entrypoint = [
      "Prowlarr"
      "-nobrowser"
    ];
    Cmd = [ "-data=/data" ];

    ExposedPorts."9696/tcp" = { };
    Volumes."/data" = { };
  };
}
