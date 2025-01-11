# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
  collectDir =
    {
      default ? "default.nix",
    }:
    dir:
    let
      contents = builtins.readDir dir;

      topFiles = lib.pipe contents [
        (lib.filterAttrs (_: type: type == "regular" || type == "symlink"))
        builtins.attrNames
        (builtins.filter (name: lib.hasSuffix ".nix" name && name != default))
        (builtins.map (name: dir + "/${name}"))
        lib.fileset.unions
      ];

      subFiles = lib.pipe contents [
        (lib.filterAttrs (_: type: type == "directory"))
        builtins.attrNames
        (builtins.map (name: dir + "/${name}/${default}"))
        (builtins.filter builtins.pathExists)
        lib.fileset.unions
      ];
    in
    lib.fileset.toList (lib.fileset.union topFiles subFiles);

  treeifyFiles = lib.flip lib.pipe [
    (builtins.map (
      f:
      lib.nameValuePair (lib.pipe f [
        builtins.dirOf
        builtins.baseNameOf
      ]) f
    ))

    builtins.listToAttrs
  ];
}
