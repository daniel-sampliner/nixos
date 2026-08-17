# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.sessionVariables.EDITOR = "nvim";

  programs.neovim = {
    enable = true;

    initLua = lib.mkMerge [
      (lib.mkOrder 0 ''
        local vim = vim
      '')

      ''
        vim.opt.exrc = true
        vim.opt.wildmode = "longest:full,full"
      ''
    ];

    plugins =
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

        pluginConfigs = lib.trivial.pipe ./plugin [
          (lib.fileset.fileFilter luaFilter)
          lib.fileset.toList

          (builtins.map (
            f:
            let
            in
            {
              plugin = lib.trivial.pipe f [
                builtins.baseNameOf
                (lib.strings.removeSuffix ".lua")
                (attr: pkgs.vimPlugins."${attr}" or pkgs.emptyFile)
              ];

              runtime."${mkRuntimeName f}".source = f;
            }
          ))
        ];
      in
      builtins.attrValues {
        inherit (pkgs.vimPlugins)
          vim-apathy
          vim-characterize
          vim-easy-align
          vim-fugitive
          vim-nix
          vim-repeat
          vim-sexp
          vim-sexp-mappings-for-regular-people
          vim-unimpaired
          ;
      }
      ++ pluginConfigs;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
