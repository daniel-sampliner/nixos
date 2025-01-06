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
  usersDir = "${src}/users";

  homeDirs = { };
  extraModules = { };

  users = lib.pipe usersDir [
    builtins.readDir
    (lib.filterAttrs (n: t: n != "profiles" && t == "directory"))
    (builtins.mapAttrs (d: _: "${usersDir}/${d}/home.nix"))
    (lib.filterAttrs (_: f: builtins.pathExists f))
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
