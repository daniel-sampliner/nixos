# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, ... }:
{
  programs.ssh = {
    enable = true;
    controlPath = "\${XDG_RUNTIME_DIR}/ssh/control-%C";

    matchBlocks = {
      zzz_yolo = {
        match = "tagged yolo";
        extraOptions = {
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
        };
      };
    };
  };

  systemd.user.tmpfiles.rules = [
    "d %t/ssh - - -"
  ];
}
