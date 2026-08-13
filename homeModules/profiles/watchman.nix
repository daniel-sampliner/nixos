# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:
let
  pkg = pkgs.watchman;

  minVer = "2025.09.22.00";
  checkVer =
    pkg:
    lib.pipe pkg [
      lib.strings.getVersion
      (v: lib.strings.versionAtLeast v minVer)
    ];
in
{
  assertions = [
    {
      assertion = checkVer pkg;
      message = "watchman profile requires watchman version >= ${minVer}";
    }
  ];

  home.packages = [ pkg ];

  programs.jujutsu.settings.fsmonitor = {
    watchman."register-snapshot-trigger" = true;
  };

  systemd.user.services.watchman = {
    Service = {
      EnvironmentFile = [ "-%t/systemd/generator/nix.env" ];
      ExecStart = "${lib.getExe pkg} --foreground --inetd --logfile=-";
      KillSignal = "SIGINT";
      Restart = "on-failure";
      StandardInput = "socket";
      StandardOutput = "journal";
    };

    Unit = {
      RefuseManualStart = true;
    };
  };

  systemd.user.sockets.watchman = {
    Socket = {
      ListenStream = [ "%S/watchman/%u-state/sock" ];
      Accept = false;
      SocketMode = "0664";
    };

    Install.WantedBy = [ "sockets.target" ];
  };
}
