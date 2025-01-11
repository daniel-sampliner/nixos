# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  inputs,
  lib,
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
    (config.lib.collectDir { default = "configuration.nix"; })
    config.lib.treeifyFiles
  ];

  homes = lib.pipe ./home/users [
    (config.lib.collectDir { default = "home.nix"; })
    config.lib.treeifyFiles
  ];

  profilesPath = ./nixos/profiles;
  hmProfilesPath = ./home/profiles;
  mkNixosSystem = host: config-nix: {
    specialArgs = { inherit profilesPath; };
    system = hostSystems.${host} or hostSystems.default;

    modules =
      config.lib.collectDir { } ./nixosModules
      ++ extraModules.${host} or [ ]
      ++ [
        inputs.home-manager.nixosModules.default

        (_: {
          home-manager = {
            extraSpecialArgs.profilesPath = hmProfilesPath;
            sharedModules = config.lib.collectDir { } ./homeModules ++ [ hmProfilesPath ];
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
