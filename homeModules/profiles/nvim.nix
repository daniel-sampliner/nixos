# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
{
  home.sessionVariables.EDITOR = "nvim";

  programs.neovim = {
    enable = true;

    plugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
        vim-apathy
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
