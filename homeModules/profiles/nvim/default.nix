# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
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

    extraLuaConfig = ''

      vim.filetype.add({
        extension = {
          ipd = 'bzl',
          star = 'bzl',
          starlark = 'bzl',
        },
      })
    '';

    plugins =
      let
        pluginConfigs = lib.trivial.pipe ./. [
          (lib.fileset.fileFilter ({ type, hasExt, ... }: type == "regular" && hasExt "lua"))
          lib.fileset.toList
          (builtins.map (f: {
            plugin = lib.trivial.pipe f [
              builtins.baseNameOf
              (lib.strings.removeSuffix ".lua")
              (lib.trivial.flip builtins.getAttr pkgs.vimPlugins)
            ];

            config = "luafile ${f}";
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
          zig-vim
          ;
      }
      ++ pluginConfigs;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
