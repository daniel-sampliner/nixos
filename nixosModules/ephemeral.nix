# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.boot.ephemeral;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.boot.ephemeral = {
    enable = lib.mkEnableOption "ephemeral system";

    store = lib.mkOption {
      default = "/persist";
      description = "Path to persistent storage location.";
      type = lib.types.path;
    };
  };

  config =
    let
      rootFS = config.fileSystems."/";
    in
    lib.mkIf cfg.enable {
      boot.tmp.useTmpfs = true;

      boot.initrd = lib.mkIf config.simpleBTRFS.enable {
        extraUtilsCommands = ''
          copy_bin_and_libs "${lib.getExe' pkgs.ephemeralBTRFS-utils-initrd "ephemeral-btrfs-nuke-root"}"
        '';
        postDeviceCommands = lib.mkBefore ''
          if root="$(blkid --label "${rootFS.label}")"; then
            DRY_RUN=no ephemeral-btrfs-nuke-root "$root" "@root" "@root-blank"
          fi
        '';
      };

      environment.systemPackages = lib.mkIf config.simpleBTRFS.enable [ pkgs.ephemeralBTRFS-utils ];

      environment.persistence.${cfg.store} = {
        hideMounts = true;

        directories = [
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

      simpleBTRFS.mounts.${cfg.store} = {
        subvolume = "@persist";
      };

      users.mutableUsers = false;

      virtualisation.vmVariant =
        let
          btrfsFSs = lib.filterAttrs (n: v: n != "/nix" && v.fsType == "btrfs") config.fileSystems;
        in
        if config.simpleBTRFS.enable then
          {
            boot.initrd = {
              extraUtilsCommands = ''
                copy_bin_and_libs "${lib.getExe' pkgs.btrfs-progs "mkfs.btrfs"}"
              '';

              luks.devices = lib.mkVMOverride { };

              postDeviceCommands =
                let
                  subvols = lib.pipe btrfsFSs [
                    (lib.filterAttrs (_: v: v.fsType or "" == "btrfs"))
                    (lib.mapAttrsToList (_: v: v.options))
                    (builtins.map (opts: lib.findFirst (o: lib.hasPrefix "subvol=" o) "" opts))
                    (builtins.filter (o: o != ""))
                    (builtins.map (o: lib.removePrefix "subvol=" o))
                  ];
                in
                lib.mkOrder 250 ''
                  if ! blkid --label "${rootFS.label}" >/dev/null; then
                    mkfs.btrfs -L "${rootFS.label}" /dev/disk/by-id/virtio-root \
                      || fail
                  fi

                  # mountFS "$(blkid --label "${rootFS.label}")" "" "" btrfs || fail
                  if ! root="$(blkid --label "${rootFS.label}")"; then
                    echo no disk with label "${rootFS.label}" >&2
                    fail
                  fi

                  mkdir -p /mnt-root
                  if ! mount -t btrfs -o subvol=/ "$root" /mnt-root; then
                    echo failed to mount "$root" to /mnt-root >&2
                    fail
                  fi

                  for subvol in ${lib.escapeShellArgs subvols}; do
                    if [ -d "/mnt-root/$subvol" ]; then
                      if ! btrfs subvolume show "/mnt-root/$subvol" >/dev/null; then
                        echo non-subvolume dir exists: "/mnt-root/$subvol" >&2
                        fail
                      fi
                      continue
                    fi
                    if ! btrfs subvolume create "/mnt-root/$subvol"; then
                      echo failed to create subvolume: "/mnt-root/$subvol" >&2
                      fail
                    fi
                    if [ "$subvol" = "@root" ]; then
                      if ! btrfs subvolume snapshot -r "/mnt-root/@root" "/mnt-root/@root-blank"; then
                        echo failed to create read-only snapshot: "/mnt/@root-blank" >&2
                        fail
                      fi
                    fi
                  done

                  umount /mnt-root
                '';
            };

            swapDevices = lib.mkVMOverride [ ];

            virtualisation.useDefaultFilesystems = false;
            virtualisation.fileSystems = btrfsFSs;
          }
        else
          {
            virtualisation.diskImage = null;
            virtualisation.fileSystems.${cfg.store} = lib.mkDefault {
              fsType = "tmpfs";
              neededForBoot = true;
            };
          };
    };
}
