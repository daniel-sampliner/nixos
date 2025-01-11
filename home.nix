# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  ...
}:
let
  homeDirs = { };
  extraModules = { };

  users = lib.trivial.pipe ./home/users [
    (config.lib.collectDir { default = "home.nix"; })
    config.lib.treeifyFiles
  ];

  profilesPath = ./home/profiles;
  mkHomeConfiguration = system: user: home-nix: {
    inherit system;
    extraSpecialArgs = { inherit profilesPath; };

    modules =
      config.lib.collectDir { } ./homeModules
      ++ extraModules.${user} or [ ]
      ++ [
        (_: { home.homeDirectory = homeDirs.${user} or "/home/${user}"; })
        profilesPath
        home-nix
      ];
  };

  mkHomeConfigurations =
    host: system:
    lib.mapAttrs' (
      user: home-nix: lib.nameValuePair "${user}@${host}" (mkHomeConfiguration system user home-nix)
    ) users;
in
lib.pipe config.nixosConfigurations [
  (builtins.mapAttrs (_: v: v.system))
  (lib.mapAttrsToList mkHomeConfigurations)
  (builtins.foldl' (a: b: a // b) { })
]
