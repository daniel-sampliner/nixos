# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
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

    plugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
        indent-o-matic
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
    };

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
