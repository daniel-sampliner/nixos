# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

_: {
  simpleBTRFS.enable = true;

  boot.initrd.luks.devices."root" = {
    allowDiscards = true;
    bypassWorkqueues = true;
    device = "/dev/disk/by-label/root.luks";
  };

  fileSystems."/boot" = {
    fsType = "vfat";
    label = "esp";
    options = [ "noatime" ];
  };

  swapDevices = [
    {
      discardPolicy = "both";
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-label/swap.luks";
        keyFile = "/mnt-root/persist/keys/swap";
        label = "swap";
      };
      label = "swap";
      priority = 10;
    }
  ];
}
