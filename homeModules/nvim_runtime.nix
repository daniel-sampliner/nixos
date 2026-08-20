# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.neovim.runtimeDir;
in
{
  options.programs.neovim.runtimeDir = lib.mkOption {
    type = lib.types.listOf lib.types.path;
    default = [ ];
  };

  config = lib.mkIf (builtins.length cfg > 0) {
    programs.neovim.plugins =
      let
        mkNeovimPlugins =
          cfgDir:
          let
            inherit (lib) fileset;

            baseDir = lib.trivial.pipe cfgDir [
              fileset.maybeMissing
              (fs: fs._internalBase)
              builtins.toString
            ];

            luaFilter = { type, hasExt, ... }: type == "regular" && hasExt "lua";

            mkRuntimeName =
              path:
              lib.trivial.pipe path [
                builtins.toString
                (lib.strings.removePrefix "${baseDir}/")
              ];

            mkPlugin = plugin: path: {
              inherit plugin;
              runtime."${mkRuntimeName path}".source = path;
            };

            pluginFiles = lib.trivial.pipe (cfgDir + "/plugin") [
              (d: if builtins.pathExists d then fileset.fileFilter luaFilter d else fileset.empty)
              fileset.toList

              (builtins.map (
                f:
                mkPlugin (lib.trivial.pipe f [
                  builtins.baseNameOf
                  (lib.strings.removeSuffix ".lua")
                  (attr: pkgs.vimPlugins."${attr}" or pkgs.emptyFile)
                ]) f
              ))
            ];

            otherFiles =
              let
                dirs = [
                  "/after"
                  "/ftplugin"
                ];
              in
              lib.trivial.pipe dirs [
                (builtins.map (dir: cfgDir + dir))
                (builtins.filter builtins.pathExists)
                (builtins.map (fileset.fileFilter luaFilter))
                fileset.unions
                fileset.toList

                (builtins.map (mkPlugin pkgs.emptyFile))
              ];
          in
          pluginFiles ++ otherFiles;
      in
      lib.trivial.pipe cfg [
        (builtins.map mkNeovimPlugins)
        lib.lists.flatten
      ];
  };
}
