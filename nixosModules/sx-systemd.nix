# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.xserver.displayManager.sx-systemd;
in
{
  options = {
    services.xserver.displayManager.sx-systemd.enable =
      lib.mkEnableOption ''dummy "sx-systemd" pseudo-display manager'';
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables.XINITRC = "${pkgs.sx-systemd}/libexec/xinitrc";

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs) sx-systemd;
      inherit (pkgs.xorg) xauth xinit;
    };

    systemd.packages = [ pkgs.sx-systemd ];

    services = {
      xserver.enable = true;
      xserver.exportConfiguration = true;
      xserver.displayManager.lightdm.enable = false;
    };

    systemd.user.services."gpg-tty" = {
      before = [ "sx-session.target" ];
      requiredBy = [ "sx-session.target" ];

      serviceConfig = {
        ExecStart =
          pkgs.writers.writeDash "gpg-tty"
            {
              check = lib.getExe pkgs.shellcheck-minimal;
            }
            ''
              set -eu

              GPG_TTY=/dev/tty''${DISPLAY#:}

              busctl --user call \
                org.freedesktop.DBus \
                /org/freedesktop/DBus \
                org.freedesktop.DBus \
                UpdateActivationEnvironment \
                'a{ss}' 1 GPG_TTY "$GPG_TTY"

              busctl --user call \
                org.freedesktop.systemd1 \
                /org/freedesktop/systemd1 \
                org.freedesktop.systemd1.Manager \
                SetEnvironment \
                'as' 1 "GPG_TTY=$GPG_TTY"
            '';

        Type = "oneshot";
      };
    };
  };
}
