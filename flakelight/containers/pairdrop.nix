# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  nix2container,
  writers,

  curl-healthchecker,
  pairdrop,
}:
nix2container.buildImage {
  name = pairdrop.pname;
  tag = pairdrop.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        curl-healthchecker
        pairdrop

        (writers.writeExecline { } "/bin/healthcheck" ''
          curl -qsSf -o /dev/null -w '%{http_code}\n' localhost:3000
        '')
      ];
    })
  ];

  config = {
    Entrypoint = [ "pairdrop" ];

    Env = [
      "RATE_LIMIT=1"
      "IPV6_LOCALIZE=4"
      "WS_FALLBACK=true"
    ];

    ExposedPorts."3000/tcp" = { };
  };
}
