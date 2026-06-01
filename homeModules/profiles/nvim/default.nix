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

        ${builtins.readFile ./starlark-ft.lua}
      ''
    ];

    plugins =
      let
        pluginConfigs = lib.trivial.pipe ./. [
          (lib.fileset.fileFilter (
            {
              name,
              type,
              hasExt,
              ...
            }:
            type == "regular"
            && hasExt "lua"
            && builtins.hasAttr (lib.strings.removeSuffix ".lua" name) pkgs.vimPlugins
          ))
          lib.fileset.toList
          (builtins.map (f: {
            plugin = lib.trivial.pipe f [
              builtins.baseNameOf
              (lib.strings.removeSuffix ".lua")
              (lib.trivial.flip builtins.getAttr pkgs.vimPlugins)
            ];

            config = ''dofile("${f}")'';
          }))
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
