# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ config, lib, ... }:
{
  boot = {
    ephemeral.enable = lib.mkDefault true;
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  services.openssh.enable = true;
  sops.userPasswords.root = ./passwd.sops;

  virtualisation.vmVariant = {
    boot.kernelParams = [ "boot.shell_on_fail" ];

    sops.userPasswords.root = lib.mkVMOverride ./build-vm.passwd.sops;

    system.activationScripts = {
      injectSOPSKey = ''
        install -Dm 0400 "${./build-vm.ssh_host_ed25519_key}" "${config.sops.key}"
      '';

      sopsUserPasswords.deps = [ "injectSOPSKey" ];
    };
  };
}
