# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ nixosTest, self' }:
(nixosTest {
  name = "ephemeral-system";

  nodes.machine =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    {
      imports = [
        self'.nixosModules.ephemeral
        self'.nixosModules.impermanence
      ];

      boot.ephemeral.enable = true;

      boot.initrd.systemd =
        let
          inherit (config.boot.initrd.systemd.extraBin) mkfs-btrfs;
          cfg = config.boot.ephemeral;
        in
        {
          enable = true;
          extraBin."mkfs-btrfs" = lib.getExe' pkgs.pkgsUnstable.btrfs-progs "mkfs.btrfs";

          services = {
            mkfs-btrfs-root = {
              after = [ "${utils.escapeSystemdPath "dev/disk/by-id/virtio-root"}.device" ];
              before = [ cfg.tmpRoot.unit ];
              partOf = [ "btrfs-init.target" ];
              requiredBy = [ cfg.tmpRoot.unit ];
              requires = [ "${utils.escapeSystemdPath "dev/disk/by-id/virtio-root"}.device" ];

              serviceConfig.RemainAfterExit = true;
              serviceConfig.Type = "oneshot";
              unitConfig.ConditionPathExists = [ "!/dev/disk/by-label/root" ];
              unitConfig.DefaultDependencies = false;

              serviceConfig.ExecStart = "${mkfs-btrfs} -L root /dev/disk/by-id/virtio-root";
            };
          };
        };

      systemd.services.dhcpcd.wantedBy = lib.mkForce [ ];
      systemd.targets."network-online".wantedBy = lib.mkForce [ ];

      virtualisation.useDefaultFilesystems = false;
      virtualisation.fileSystems = {
        "/" = {
          fsType = "btrfs";
          label = "root";
          options = [ "subvol=@root" ];
          neededForBoot = true;
        };
        "/var/log" = {
          fsType = "btrfs";
          label = "root";
          options = [ "subvol=@log" ];
          neededForBoot = true;
        };
      };
    };

  interactive.nodes.machine = _: {
    boot.kernelParams = [ "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1" ];
    boot.initrd.systemd.services.panic-on-fail.enable = false;
    services.getty.autologinUser = "root";
  };

  testScript = ''
    machine.start(allow_reboot=True)
    machine.succeed("systemctl --wait is-system-running")

    machine.succeed("touch /etc/should_disappear")
    machine.succeed("touch /persist/should_persist")
    machine_id = machine.succeed("cat /etc/machine-id")

    machine.reboot()
    machine.succeed("systemctl --wait is-system-running")

    machine.succeed("[[ ! -e /etc/should_disappear ]]")
    machine.succeed("[[ -f /persist/should_persist ]]")
    assert machine_id == machine.succeed("cat /etc/machine-id")
    assert len(machine.succeed("journalctl --list-boots").strip().split("\n")) == 3
  '';
}).driver
