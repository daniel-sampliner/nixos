# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  nix2container,
  writeText,
  writers,

  catatonit,
  coreutils,
  curl-healthchecker,
  jq,
  snooze,

  bashInteractive,
}:
let
  vol = "/srv";
  marker = "${vol}/last";

  entrypoint =
    let
      curlCmd = "curl $CURL_ARGS --silent --show-error --max-time 3 --retry 10 --retry-connrefused";
      backupPayload = writeText "backup-payload.json" (
        builtins.toJSON {
          msgtype = "m.text";
          body = ''\!admin server backup-database'';
        }
      );
    in
    writers.writeExecline { flags = "-WS0"; } "/bin/entrypoint" ''
      multisubstitute {
        importas -i CREDS_FILE CREDS_FILE
        importas -i HOMESERVER HOMESERVER
        importas -i ROOM_ID ROOM_ID
        importas -i -s CURL_ARGS CURL_ARGS
      }
      define baseUrl ''${HOMESERVER}/_matrix/client/v3

      loopwhilex -o 0

      backtick -E uuid { cat /proc/sys/kernel/random/uuid }
      snooze -t "${marker}" $@

      if {
        pipeline { ${curlCmd} --fail ''${baseUrl}/login --json @''${CREDS_FILE} }
        pipeline { jq -re ".access_token? | select(. != null) | \"Authorization: Bearer \" + ." }
        ${curlCmd} --fail-with-body ''${baseUrl}/rooms/''${ROOM_ID}/send/m.room.message/''${uuid}
          -X PUT
          -H @-
          --write-out "\n"
          --json "@${backupPayload}"
      }
      touch "${marker}"
    '';

  healthcheck = writers.writeExecline { } "/bin/healthcheck" ''
    if { eltest -f "${marker}" }
    if { touch -d -1day /run/check }
    eltest "${marker}" -nt /run/check
  '';
in
nix2container.buildImage {
  name = "conduwuit-backup";
  tag = "0.0.2";

  copyToRoot = buildEnv {
    name = "root";
    paths = [
      catatonit
      coreutils
      curl-healthchecker
      jq
      snooze

      entrypoint
      healthcheck

      bashInteractive
    ];
    pathsToLink = [ "/bin" ];
  };

  config = {
    Entrypoint = [
      "catatonit"
      "-g"
      "--"
      "entrypoint"
    ];
    Cmd = [
      "-v"
      "-d*"
      "-m*"
      "-w*"
      "-H0"
      "-M0"
      "-S0"
      "-s1d"
    ];

    Healthcheck.Test = [
      "CMD"
      "healthcheck"
    ];

    User = "65534:65534";
    Volumes.${vol} = { };
  };
}
