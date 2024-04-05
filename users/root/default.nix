# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ lib, pkgs, ... }:
{
  sops.userPasswords.root = ./passwd.sops;

  users.users.root.shell = pkgs.zsh;

  virtualisation.vmVariant = {
    sops.userPasswords.root = lib.mkVMOverride ./build-vm.passwd.sops;
  };
}
