# SPDX-FileCopyrightText: 2024, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  curlMinimal,
  dockerTools,
  ffmpeg-headless,
  nix2container,
  sonarr,
  writers,
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
        curlMinimal
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
