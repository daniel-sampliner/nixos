# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  inputs,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.boot.ephemeral;

  systemdPath =
    path:
    lib.pipe path [
      (lib.removePrefix "/")
      utils.escapeSystemdPath
    ];
in
{
  options.boot.ephemeral = {
    enable = lib.mkEnableOption "ephemeral system";

    rootDevice = lib.mkOption {
      apply = d: {
        path = d;
        unit = systemdPath "${d}.path";
      };
      default = "/dev/disk/by-label/root";
      description = "System root device.";
      type = lib.types.path;
    };

    store = lib.mkOption {
      default = "/persist";
      description = "Path to persistent storage location.";
      type = lib.types.path;
    };

    tmpRoot = lib.mkOption {
      apply = p: {
        path = p;
        unit = systemdPath "${p}.mount";
      };
      default = "/mnt/btrfsroot";
      readOnly = true;
      type = lib.types.path;
      visible = false;
    };
  };

  config =
    let
      persistFS = {
        fsType = "btrfs";
        device = cfg.rootDevice.path;
        options = [ "subvol=@${builtins.baseNameOf cfg.store}" ];
        neededForBoot = true;
      };
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.fileSystems."/".fsType == "btrfs";
          message = "root fsType ${config.fileSystems."/".fsType} != btrfs";
        }
        {
          assertion = config.boot.initrd.systemd.enable;
          message = "boot.initrd.systemd not enabled";
        }
      ];

      boot.initrd.systemd =
        let
          inherit (config.boot.initrd.systemd.extraBin) btrfs;

          subvols = lib.pipe config.fileSystems [
            (lib.filterAttrs (n: _: n != "/nix"))
            (lib.filterAttrs (n: v: v ? fsType))
            (lib.filterAttrs (_: v: v.fsType == "btrfs"))
            (lib.mapAttrsToList (_: v: v.options))
            (builtins.map (opts: lib.findFirst (o: lib.hasPrefix "subvol=" o) "" opts))
            (builtins.filter (o: o != ""))
            (builtins.map (o: lib.removePrefix "subvol=@" o))
          ];
        in
        {
          extraBin."btrfs" = lib.getExe' pkgs.pkgsUnstable.btrfs-progs "btrfs";

          mounts = [
            {
              after = [ "local-fs.target" ];
              partOf = [ "btrfs-init.target" ];
              unitConfig.DefaultDependencies = false;

              options = "subvol=/";
              type = "btrfs";
              what = cfg.rootDevice.path;
              where = cfg.tmpRoot.path;
            }
          ];

          services =
            {
              nuke-btrfs-root = {
                after = [ cfg.tmpRoot.unit ];
                before = [
                  "btrfs-init.target"
                  "make-btrfs-subvol@root.service"
                ];
                partOf = [ "btrfs-init.target" ];
                requires = [ cfg.tmpRoot.unit ];
                requiredBy = [ "make-btrfs-subvol@root.service" ];
                serviceConfig.RemainAfterExit = true;
                serviceConfig.Type = "oneshot";
                unitConfig.ConditionPathExists = [
                  "${cfg.tmpRoot.path}/@root"
                  "!/sysroot"
                ];
                unitConfig.AssertPathExists = "${cfg.tmpRoot.path}/@root-blank";
                unitConfig.DefaultDependencies = false;

                serviceConfig.ExecStart = "${btrfs} subvolume delete --recursive '${cfg.tmpRoot.path}/@root'";
              };

              "make-btrfs-subvol@" = {
                after = [ cfg.tmpRoot.unit ];
                before = [ "btrfs-init.target" ];
                partOf = [ "btrfs-init.target" ];
                requires = [ cfg.tmpRoot.unit ];
                serviceConfig.RemainAfterExit = true;
                serviceConfig.Type = "oneshot";
                unitConfig.ConditionPathExists = [ "!${cfg.tmpRoot.path}/@%I" ];
                unitConfig.DefaultDependencies = false;

                serviceConfig.ExecStart = "${btrfs} subvolume create ${cfg.tmpRoot.path}/@%I";
              };

              snap-btrfs-root = {
                after = [
                  "make-btrfs-subvol@root.service"
                  cfg.tmpRoot.unit
                ];
                before = [ "btrfs-init.target" ];
                partOf = [ "btrfs-init.target" ];
                requiredBy = [ "btrfs-init.target" ];
                requires = [
                  "make-btrfs-subvol@root.service"
                  cfg.tmpRoot.unit
                ];
                serviceConfig.RemainAfterExit = true;
                serviceConfig.Type = "oneshot";
                unitConfig.ConditionPathExists = [ "!${cfg.tmpRoot.path}/@root-blank" ];
                unitConfig.DefaultDependencies = false;

                serviceConfig.ExecStart = "${btrfs} subvolume snap -r ${cfg.tmpRoot.path}/@root ${cfg.tmpRoot.path}/@root-blank";
              };
            }
            // lib.pipe subvols [
              (builtins.map (
                s:
                lib.nameValuePair "make-btrfs-subvol@${s}" {
                  overrideStrategy = "asDropin";
                  requiredBy = [ "btrfs-init.target" ];
                }

              ))

              (builtins.listToAttrs)
            ];

          targets.btrfs-init = {
            description = "Ephemeral BTRFS initialized";

            before = [
              "create-needed-for-boot-dirs.service"
              "initrd-cleanup.service.service"
              "sysroot.mount"
            ];
            conflicts = [ "initrd-cleanup.service.service" ];
            requiredBy = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = false;
          };
        };

      environment.persistence.${cfg.store} = {
        hideMounts = true;

        directories =
          [
            "/var/lib/nixos"
            "/var/lib/systemd"
          ]
          ++ (lib.optional config.hardware.bluetooth.enable "/var/lib/bluetooth")
          ++ (lib.optional config.networking.wireless.iwd.enable "/var/lib/iwd")
          ++ (lib.optional config.services.flatpak.enable "/var/lib/flatpak");

        files = [
          "/etc/adjtime"
          "/etc/machine-id"
        ];
      };

      fileSystems.${cfg.store} = persistFS;

      services.openssh.hostKeys =
        let
          mkKey =
            type:
            {
              inherit type;
              path = "${cfg.store}/keys/ssh/ssh_host_${type}_key";
              comment = config.networking.hostName;
            }
            // lib.optionalAttrs (type == "rsa") { bytes = 4096; };
        in
        builtins.map mkKey [
          "ed25519"
          "rsa"
        ];

      system.etc.overlay.mutable = false;
      users.mutableUsers = false;
      virtualisation.fileSystems.${cfg.store} = persistFS;
    };
}
