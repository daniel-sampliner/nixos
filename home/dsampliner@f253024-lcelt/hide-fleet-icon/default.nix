# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  name = "plasma-hide-fleet";

  script = pkgs.execline.passthru.writeScript "${name}-script" "-WS0" ''
    backtick -E pid { pgrep fleet-desktop }
    backtick -E script { sed -e "s/@PID@/''${pid}/g" "${./script.js}" }

    qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"
  '';
in
{
  systemd.user.services.plasma-hide-fleet = {
    Service = {
      ExecStart = "${script}";
      Restart = "on-failure";
      RestartMaxDelaySec = "10s";
      RestartSteps = "5";
      StartLimitBurst = "10";
      StartLimitInterval = "60s";
      Type = "oneshot";
    };
    Install.WantedBy = [ "plasma-workspace.target" ];
  };
}
