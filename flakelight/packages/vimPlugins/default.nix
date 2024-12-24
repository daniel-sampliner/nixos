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
linkFarm "vimPlugins" (builtins.mapAttrs (_: drv: drv.outPath) plugins)
// {
  meta.license = lib.pipe plugins [
    (lib.mapAttrsToList (_: p: p.meta.license or [ ]))
    lib.flatten
    lib.unique
  ];
}
// vimPlugins
// plugins
