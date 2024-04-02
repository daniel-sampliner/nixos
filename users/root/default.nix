# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ lib, ... }:
{
  sops.userPasswords.root = ./passwd.sops;

  virtualisation.vmVariant = {
    sops.userPasswords.root = lib.mkVMOverride ./build-vm.passwd.sops;
  };
}
