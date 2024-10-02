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

  catatonit,
  conduwuit,

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
in
nix2container.buildImage {
  name = conduwuit.pname;
  tag = conduwuit.version;

  layers = lib.singleton (
    nix2container.buildLayer { deps = builtins.map (builtins.getAttr "newDependency") replacements; }
  );

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        dockerTools.caCertificates
        catatonit

        conduwuit-stripped
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
