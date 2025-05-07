# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib }:
let
  collectDir =
    {
      default ? "default.nix",
      exclude ? lib.fileset.difference ./collect.nix ./collect.nix,
    }:
    dir:
    let
      contents = builtins.readDir dir;

      topFiles = lib.trivial.pipe contents [
        (lib.filterAttrs (_: type: type == "regular" || type == "symlink"))
        builtins.attrNames
        (builtins.filter (name: lib.hasSuffix ".nix" name && name != default))
        (builtins.map (name: dir + "/${name}"))
        lib.fileset.unions
      ];

      subFiles = lib.trivial.pipe contents [
        (lib.filterAttrs (_: type: type == "directory"))
        builtins.attrNames
        (builtins.map (name: dir + "/${name}/${default}"))
        (builtins.filter builtins.pathExists)
        lib.fileset.unions
      ];
    in
    lib.trivial.pipe topFiles [
      (lib.trivial.flip lib.fileset.union subFiles)
      (lib.trivial.flip lib.fileset.difference exclude)
      lib.fileset.toList
    ];

  collectDirAttrs =
    args: dir:
    lib.trivial.pipe (collectDir args dir) [
      (builtins.map (
        p:
        lib.attrsets.nameValuePair (lib.pipe p [
          (
            p:
            let
              base = builtins.baseNameOf p;
            in
            if base == args.default or "default.nix" then
              lib.trivial.pipe p [
                builtins.dirOf
                builtins.baseNameOf
              ]
            else
              lib.strings.removeSuffix ".nix" base
          )
        ]) p
      ))

      builtins.listToAttrs
    ];

in
{
  inherit collectDir collectDirAttrs;
}
