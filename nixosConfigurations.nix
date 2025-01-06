# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  inputs,
  lib,
  outputs,
  src,
  ...
}:
let
  hostsDir = src + "/hosts";

  hostSystems = {
    default = "x86_64-linux";
  };

  extraModules = {
    "thiccpad" = [ inputs.nixos-hardware.nixosModules.lenovo-legion-16ach6h-nvidia ];
  };

  hosts = lib.pipe hostsDir [
    (lib.fileset.fileFilter ({ name, ... }: name == "configuration.nix"))
    lib.fileset.toList

    (builtins.map (
      f:
      lib.nameValuePair (lib.pipe f [
        builtins.dirOf
        builtins.baseNameOf
      ]) f
    ))

    builtins.listToAttrs
  ];

  mkNixosSystem = host: config-nix: {
    system = hostSystems.${host} or hostSystems.default;

    modules =
      builtins.attrValues outputs.nixosModules or { }
      ++ extraModules.${host} or [ ]
      ++ [
        inputs.home-manager.nixosModules.default

        (_: {
          home-manager.sharedModules = builtins.attrValues outputs.homeModules or { };
          networking.hostName = builtins.baseNameOf host;
          nixpkgs.config = config.nixpkgs.config;
        })

        config-nix
      ];
  };
in
builtins.mapAttrs mkNixosSystem hosts
