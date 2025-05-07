# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ nixosTest, self' }:
(nixosTest {
  name = "sx-systemd";

  nodes.machine =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ self'.nixosModules.sx-systemd ];

      environment.systemPackages = [ pkgs.xdotool ];
      programs.bash.promptInit = "PS1='# '";
      services.getty.autologinUser = "root";
      services.xserver.displayManager.sx-systemd.enable = true;

      systemd.services.dhcpcd.wantedBy = lib.mkForce [ ];
      systemd.targets."network-online".wantedBy = lib.mkForce [ ];

      systemd.user.services.xterm = {
        partOf = [ "graphical-session.target" ];
        requisite = [ "graphical-session.target" ];
        after = [ "sx-session.target" ];
        wantedBy = [ "sx-session.target" ];

        serviceConfig = {
          ExecStart = lib.getExe' pkgs.xterm "xterm";
        };
      };
    };

  testScript = ''
    prompt = "# "
    user = "root"

    with subtest("Wait for the autologin"):
        machine.wait_until_tty_matches("1", prompt)

    with subtest("Start sx-systemd"):
        machine.send_chars("systemd-cat -t sx sx\n")
        machine.wait_for_file("/tmp/.X11-unix/X1")
        machine.wait_until_succeeds("pgrep -fa '[s]ystemctl .* sx-session.target'")
        machine.wait_for_unit("graphical-session.target", user)
        machine.wait_for_unit("xterm.service", user)


    def xtype(s: str) -> str:
        return (
            "export DISPLAY=:1 XAUTHORITY=/run/user/0/Xauthority"
            f" && xdotool search xterm windowfocus --sync type '{s}'"
            " && xdotool search xterm windowfocus --sync key Return"
        )


    with subtest("Check -pre services"):
        f = f"/{user}/gpg_tty"
        machine.wait_until_succeeds(xtype(f"echo $GPG_TTY | tee {f}"))
        machine.wait_for_file(f)
        machine.succeed(f"[[ $(<{f}) == /dev/tty1 ]]")

    with subtest("Can stop X"):
        machine.wait_until_succeeds(xtype("systemctl stop --user sx-session.target"))
        machine.wait_until_tty_matches("1", prompt)
  '';
}).driver
