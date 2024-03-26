# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  inputs,
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

  config = lib.mkIf cfg.enable {
    boot.tmp.useTmpfs = true;

    environment.persistence.${cfg.store} = {
      hideMounts = true;

      directories =
        [ "/var/lib/systemd" ]
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
      neededForBoot = true;
    };

    users.mutableUsers = false;

    virtualisation.vmVariant = {
      virtualisation.diskImage = null;
      virtualisation.fileSystems.${cfg.store} = {
        fsType = "tmpfs";
        neededForBoot = true;
      };
    };
  };
}
