# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  diceware,
  lib,
  nixosTest,
  openssh,
  runCommand,
  self',
  sops,
  ssh-to-age,
}:
let
  password = lib.strings.fileContents passwordFile;

  passwordFile = runCommand "password" { } ''
    ${lib.getExe diceware} --no-caps -d - >$out
  '';

  password-sops = runCommand "password-sops" { } ''
    echo "alice:${password}" >$out
    ${lib.getExe sops} --age $(${lib.getExe ssh-to-age} -i ${sshHostKey}/key.pub) -i -e $out
  '';

  sshHostKey = runCommand "ssh-host-key" { } ''
    mkdir -p $out
    ${lib.getExe' openssh "ssh-keygen"} -f $out/key -N "" -t ed25519
  '';
in
(nixosTest {
  name = "sops";
  nodes.machine =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/../tests/common/user-account.nix")
        self'.nixosModules.sops
      ];

      services.openssh.enable = true;
      services.userborn.enable = true;
      sops.importKey = "${sshHostKey}/key";
      sops.chpasswd = password-sops.outPath;
      sops.secrets.test = password-sops.outPath;

      systemd.services.sops-test = {
        before = [ "multi-user.target" ];
        requiredBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "notify";
          LoadCredential = "test:${config.sops.socket}";
        };
        script = ''
          cat $CREDENTIALS_DIRECTORY/test >/tmp/sops-test.out
          systemd-notify --ready
          sleep +inf
        '';
      };

      systemd.services.dhcpcd.wantedBy = lib.mkForce [ ];
      systemd.targets."network-online".wantedBy = lib.mkForce [ ];

      users.users.alice.password = lib.mkForce null;
    };

  interactive.nodes.machine = _: {
    services.getty.autologinOnce = true;
    services.getty.autologinUser = "root";
  };

  testScript = ''
    machine.succeed("systemctl --wait is-system-running")

    with subtest("Check sshd serving age key"):
        machine.wait_for_unit("sshd.service")
        with open("${sshHostKey}/key", "r") as f:
            assert (
                f.read().strip()
                == machine.succeed(
                    "systemd-creds decrypt /etc/credstore.encrypted/sops-nix/control/ssh_host_ed25519_key"
                ).strip()
            )

        with open("${sshHostKey}/key.pub", "r") as f:
            want = f.read().strip()
            assert want == machine.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub").strip()
            want_l = want.split()
            want = f"{want_l[0]} {want_l[1]}"
            assert want in machine.succeed("ssh-keyscan localhost")

    with subtest("Log in as alice"):
        machine.send_key("alt-f2")
        machine.wait_until_tty_matches("2", "login: ")
        machine.send_chars("alice\n")
        machine.wait_until_tty_matches("2", "Password: ")
        machine.send_chars("${password}\n")
        machine.wait_until_tty_matches("2", r"\[alice@.*\]\$")
        machine.send_chars("touch alice.done\n")
        machine.wait_for_file("/home/alice/alice.done")
        machine.send_chars("exit\n")
        machine.send_key("alt-f1")

    with subtest("Check sops-test service"):
        machine.wait_for_unit("sops-test.service")
        machine.wait_for_file("/tmp/sops-test.out")
        assert "${password}" in machine.succeed("cat /tmp/sops-test.out")
  '';
}).driver
