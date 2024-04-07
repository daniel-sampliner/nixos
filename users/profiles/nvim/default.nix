# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ pkgs, ... }:
{
  home.sessionVariables.EDITOR = "nvim";

  programs.neovim = {
    enable = true;

    extraConfig = ''
      let g:do_filetype_lua = 1
    '';

    plugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
        vim-apathy
        vim-characterize
        vim-easy-align
        vim-fugitive
        vim-nix
        vim-repeat
        vim-sleuth
        vim-surround
        vim-unimpaired
        ;
    };

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
