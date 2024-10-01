# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  lib,
  nix2container,
  runCommand,
  writeTextFile,

  s6-networking,
  tipidee,
}:
let
  tipidee-conf = writeTextFile {
    name = "tipidee.conf";
    destination = "/etc/tipidee.conf";
    text = ''
      custom-header add Access-Control-Allow-Headers X-Requested-With, Content-Type, Authorization
      custom-header add Access-Control-Allow-Methods GET, POST, PUT, DELETE, OPTIONS
      custom-header add Access-Control-Allow-Origin *
      custom-header add Cache-Control public, max-age=86400
      log request user-agent x-forwarded-for answer answer_size
    '';
  };

  tipidee-conf-cdb = runCommand "tipidee.conf.cdb" { } ''
    mkdir -p $out/etc
    ${lib.getExe' tipidee "tipidee-config"} \
      -i ${tipidee-conf}/etc/tipidee.conf \
      -o $out/etc/tipidee.conf.cdb
  '';
in
nix2container.buildImage {
  name = "well-known";
  tag = tipidee.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        s6-networking
        tipidee

        tipidee-conf
        tipidee-conf-cdb
      ];
    })
  ];

  config = {
    Entrypoint = [
      "s6-tcpserver"
      "0.0.0.0"
      "80"
      "tipideed"
      "-d"
      "/var/lib/tipideed"
      "-R"
      "-U"
    ];

    Env = [
      "UID=65534"
      "GID=65534"
    ];

    ExposedPorts = {
      "80/tcp" = { };
    };

    Volumes = {
      "/var/lib/tipideed" = { };
    };
  };
}
