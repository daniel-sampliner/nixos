# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, config, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "no";
        Compression = false;
        ControlMaster = "no";
        ControlPath = "\${XDG_RUNTIME_DIR}/ssh/control-%C";
        ControlPersist = "no";
        ForwardAgent = false;
        HashKnownHosts = false;
        ServerAliveCountMax = 3;
        ServerAliveInterval = 0;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };

      "Match tagged yolo" = {
        LogLevel = "ERROR";
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = "no";
      };
    };
  };

  systemd.user.tmpfiles.rules = [
    "d %t/ssh - - -"
  ];
}
