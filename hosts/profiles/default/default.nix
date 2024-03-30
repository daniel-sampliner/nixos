# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ lib, ... }:
{
  boot = {
    ephemeral.enable = lib.mkDefault true;
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  sops.userPasswords.root = ./passwd.sops;

  virtualisation.vmVariant = {
    boot.kernelParams = [ "boot.shell_on_fail" ];

    services.openssh.hostKeys = lib.mkVMOverride [
      {
        type = "ed25519";
        path = ./build-vm.ssh_host_ed25519_key;
      }
    ];

    sops.userPasswords.root = lib.mkVMOverride ./build-vm.passwd.sops;
  };
}
