# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

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
