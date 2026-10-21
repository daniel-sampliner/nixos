# SPDX-FileCopyrightText: 2024, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  curlMinimal,
  dockerTools,
  nix2container,
  syncthing,
  writers,
}:
nix2container.buildImage {
  name = syncthing.pname;
  tag = syncthing.version;

  copyToRoot = [
    dockerTools.caCertificates

    (buildEnv {
      name = "root";
      paths = [
        curlMinimal
        syncthing

        (writers.writeExecline { } "/bin/healthcheck" ''
          importas -s CURL_ARGS CURL_ARGS
          curl -qfsS $CURL_ARGS http://localhost:8384/rest/noauth/health
        '')
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Entrypoint = [
      "syncthing"
      "serve"
    ];
    Cmd = [ "--no-browser" ];

    Env = [
      "STCONFDIR=/config"
      "STDATADIR=/data"
      "STNODEFAULTFOLDER=true"
      "STNORESTART=true"
    ];
    ExposedPorts = {
      "21027/udp" = { };
      "22000/tcp" = { };
      "22000/udp" = { };
    };
    Volumes = {
      "/config" = { };
      "/data" = { };
    };
  };
}
