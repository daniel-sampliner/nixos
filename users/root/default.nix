# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
{
  sops.userPasswords.root = ./passwd.sops;

  users.users.root.shell = pkgs.zsh;

  virtualisation.vmVariant = {
    sops.userPasswords.root = lib.mkVMOverride ./build-vm.passwd.sops;
  };
}
