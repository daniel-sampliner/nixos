# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  outputs,
  src,
  ...
}:
let
  usersDir = src + "/users";

  homeDirs = { };
  extraModules = { };

  users = lib.trivial.pipe usersDir [
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

  mkHomeConfiguration = system: user: config: {
    inherit system;

    modules =
      builtins.attrValues outputs.homeModules or { }
      ++ extraModules.${user} or [ ]
      ++ [
        (_: { home.homeDirectory = homeDirs.${user} or "/home/${user}"; })
        config
      ];
  };

  mkHomeConfigurations =
    host: system:
    lib.mapAttrs' (
      user: config: lib.nameValuePair "${user}@${host}" (mkHomeConfiguration system user config)
    ) users;
in
lib.pipe config.nixosConfigurations [
  (builtins.mapAttrs (_: v: v.system))
  (lib.mapAttrsToList mkHomeConfigurations)
  (builtins.foldl' (a: b: a // b) { })
]
