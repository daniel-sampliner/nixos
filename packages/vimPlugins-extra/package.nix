# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  callPackage,
  lib,
  linkFarm,
}:
let
  plugins = lib.trivial.pipe ./. [
    (lib.collectDirAttrs { default = "package.nix"; })
    (builtins.mapAttrs (_: v: callPackage v { }))
  ];
in
linkFarm "vimPlugins" plugins // { passthru = { inherit plugins; }; }
