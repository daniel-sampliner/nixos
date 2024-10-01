# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  nix2container,

  catatonit,
  conduwuit,
}:
nix2container.buildImage {
  name = conduwuit.pname;
  tag = conduwuit.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        dockerTools.caCertificates
        catatonit
        conduwuit
      ];
    })
  ];

  config =
    let
      dbPath = "/var/lib/conduwuit";
    in
    {
      Env = [
        "CONDUWUIT_DATABASE_PATH=${dbPath}"
        "CONDUWUIT_DATABASE_BACKEND=rocksdb"
      ];

      Entrypoint = [
        "catatonit"
        "--"
        "conduit"
      ];

      Volumes.${dbPath} = { };
    };
}
