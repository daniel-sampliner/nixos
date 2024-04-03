# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ lib, pkgs, ... }:
let
  name = "daniel";
  uid = 1000;
in
{
  home-manager.users.${name} = import ./home.nix;
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
