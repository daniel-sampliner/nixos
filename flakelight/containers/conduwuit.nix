# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  lib,
  nix2container,
  noopPkg,
  replaceDependencies,
  writers,

  conduwuit,
  curl-healthchecker,

  # unneeded dependencies
  gcc,
  rustc,
}:
let
  unneeded = [
    gcc
    rustc.unwrapped
  ];

  replacements = builtins.map (pkg: {
    oldDependency = pkg;
    newDependency = noopPkg pkg;
  }) unneeded;

  conduwuit-stripped = replaceDependencies {
    inherit replacements;
    drv = conduwuit;
  };

  healthcheck = writers.writeExecline { flags = "-WS0"; } "/bin/healthcheck" ''
    curl -qsSf
      --max-time 1
      --retry 10
      --retry-max-time 15
      $@
      http://localhost:8008/_matrix/client/versions
  '';
in
nix2container.buildImage {
  name = conduwuit.pname;
  tag = conduwuit.version;

  layers = lib.singleton (
    nix2container.buildLayer { deps = builtins.map (builtins.getAttr "newDependency") replacements; }
  );

  copyToRoot = [
    dockerTools.caCertificates
    (buildEnv {
      name = "root";
      paths = [
        conduwuit-stripped
        curl-healthchecker
        healthcheck
      ];
      pathsToLink = [ "/bin" ];
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

      Entrypoint = [ "conduit" ];

      Healthcheck.Test = [
        "CMD"
        "healthcheck"
      ];

      Volumes.${dbPath} = { };
    };
}
