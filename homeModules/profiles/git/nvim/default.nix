# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:
{
  programs.neovim.extraPackages = [ pkgs.commitmsgfmt ];

  programs.neovim.plugins =
    let
      luaFilter = { type, hasExt, ... }: type == "regular" && hasExt "lua";

      baseDir = lib.pipe ./default.nix [
        lib.fileset.toList
        builtins.head
        builtins.dirOf
        builtins.toString
      ];

      mkRuntimeName =
        path:
        lib.trivial.pipe path [
          builtins.toString
          (lib.strings.removePrefix "${baseDir}/")
        ];

      pluginConfigs = lib.trivial.pipe ./after [
        (lib.fileset.fileFilter luaFilter)
        lib.fileset.toList

        (builtins.map (f: {
          plugin = pkgs.emptyFile;
          runtime."${mkRuntimeName f}".source = f;
        }))
      ];
    in
    builtins.attrValues {
      inherit (pkgs.vimPlugins)
        vim-fugitive
        ;
    }
    ++ pluginConfigs;
}
