# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  flakelight,
  lib,
  linkFarm,
  pkgs,
  vimPlugins,
}:
let
  plugins = lib.pipe ./. [
    flakelight.importDir
    (builtins.mapAttrs (_: v: pkgs.callPackage v { }))
  ];
in
linkFarm "vimPlugins" (
  lib.mapAttrsToList (name: drv: {
    inherit name;
    path = drv.outPath;
  }) plugins
)
// vimPlugins
// plugins
