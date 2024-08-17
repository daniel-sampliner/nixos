# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  nix2container,
  writeTextFile,
  writers,

  chrony,
  s6,
  s6-portable-utils,
}:
let
  chrony-conf = writeTextFile {
    name = "chrony.conf";
    destination = "/etc/chrony.conf";
    text = ''
      bindcmdaddress 0.0.0.0
      bindcmdaddress ::
      cmdallow all

      driftfile /var/lib/chrony/drift
      dumpdir /var/lib/chrony
      pidfile /run/chrony/chronyd.pid
      rtconutc
      rtcsync

      sourcedir /run/chrony
    '';
  };

  entrypoint = writers.writeExecline { flags = "-Ws0"; } "/bin/entrypoint" ''
    importas -D nobody USER USER

    s6-envuidgid $USER
    if { s6-chown -U /run/chrony }
    if { s6-chown -U /var/lib/chrony }

    emptyenv -c
    exec -a chronyd chronyd -u $USER $@
  '';

  healthcheck = writers.writeExecline { } "/bin/healthcheck" ''
    s6-setuidgid nobody
    chronyc waitsync 1
  '';
in
nix2container.buildImage {
  name = chrony.pname;
  tag = chrony.version;

  copyToRoot = [
    chrony-conf
    entrypoint
    healthcheck

    (buildEnv {
      name = "root";
      paths = [
        chrony
        s6
        s6-portable-utils
      ];

      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Env = [
      "PATH=/bin"
      "USER=nobody"
    ];

    Entrypoint = [ "entrypoint" ];
    Cmd = [
      "-d"
      "-r"
      "-s"
      "-F"
      "1"
    ];

    Volumes = {
      "/run/chrony" = { };
      "/var/lib/chrony" = { };
    };
  };
}
