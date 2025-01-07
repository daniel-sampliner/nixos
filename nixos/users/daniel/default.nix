# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  name = "daniel";
  uid = 1000;
in
{
  sops.userPasswords.${name} = ./passwd.sops;
  users.groups.${name}.gid = uid;

  users.users.${name} = {
    inherit uid;

    autoSubUidGidRange = true;
    group = name;
    isNormalUser = true;
    shell = pkgs.zsh;

    extraGroups = [
      "users"
      "wheel"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVYErvS1RkXIUNOhGXgr0GABhQoz4DUgkDTcFCxkdJD openpgp:0x15492387"
    ];
  };

  virtualisation.vmVariant = {
    sops.userPasswords.${name} = lib.mkVMOverride ./build-vm.passwd.sops;
  };
}
