# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  inputs,
  lib,
  outputs,
  ...
}:
let
  hostSystems = {
    default = "x86_64-linux";
  };

  extraModules = {
    "thiccpad" = [ inputs.nixos-hardware.nixosModules.lenovo-legion-16ach6h-nvidia ];
  };

  hosts = lib.pipe ./nixos/hosts [
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

  homes = lib.pipe ./home/users [
    (lib.fileset.fileFilter ({ name, ... }: name == "home.nix"))
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

  profilesPath = ./nixos/profiles;
  hmProfilesPath = ./home/profiles;
  mkNixosSystem = host: config-nix: {
    specialArgs = { inherit profilesPath; };
    system = hostSystems.${host} or hostSystems.default;

    modules =
      builtins.attrValues outputs.nixosModules or { }
      ++ extraModules.${host} or [ ]
      ++ [
        inputs.home-manager.nixosModules.default

        (_: {
          home-manager = {
            extraSpecialArgs.profilesPath = hmProfilesPath;
            sharedModules = builtins.attrValues outputs.homeModules or { } ++ [ hmProfilesPath ];
            users = builtins.mapAttrs (_: import) homes;
          };

          networking.hostName = builtins.baseNameOf host;
          nixpkgs.config = config.nixpkgs.config;
        })

        profilesPath
        config-nix
      ];
  };
in
builtins.mapAttrs mkNixosSystem hosts
