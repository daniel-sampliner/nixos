# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
{
  systemd.user.services.notify-cancel = {
    Service = {
      ExecStart = lib.getExe pkgs.pkgsExtra.notify-cancel;
      Restart = "on-failure";
      Type = "notify";
    };

    Install.WantedBy = [ "graphical-session.target" ];

    Unit = {
      After = [ "dbus.socket" ];
      Requires = [ "dbus.socket" ];
    };
  };
}
