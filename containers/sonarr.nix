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
  sonarr,
}:
nix2container.buildImage {
  name = sonarr.pname;
  tag = sonarr.version;

  copyToRoot = [
    dockerTools.caCertificates
    dockerTools.fakeNss

    (buildEnv {
      name = "root";
      paths = [
        curl-healthchecker
        ffmpeg-headless
        sonarr

        (writers.writeExecline { } "/bin/healthcheck" ''
          curl -qSsf http://localhost:8989/ping
        '')
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Entrypoint = [
      "NzbDrone"
      "-nobrowser"
    ];
    Cmd = [ "-data=/data" ];

    ExposedPorts."8989/tcp" = { };
    Volumes."/data" = { };
  };
}
