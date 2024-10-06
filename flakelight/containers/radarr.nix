# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  nix2container,
  writers,

  curl-healthchecker,
  ffmpeg-headless,
  radarr,
}:
nix2container.buildImage {
  name = radarr.pname;
  tag = radarr.version;

  copyToRoot = [
    dockerTools.caCertificates
    dockerTools.fakeNss

    (buildEnv {
      name = "root";
      paths = [
        curl-healthchecker
        ffmpeg-headless
        radarr

        (writers.writeExecline { } "/bin/healthcheck" ''
          curl -qSsf http://localhost:7878/ping
        '')
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Entrypoint = [
      "Radarr"
      "-nobrowser"
    ];
    Cmd = [ "-data=/data" ];

    ExposedPorts."7878/tcp" = { };
    Volumes."/data" = { };
  };
}
