# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:
{
  home.sessionVariables.EDITOR = "nvim";

  programs.neovim = {
    enable = true;
    extraPackages = [ pkgs.nixd ];

    initLua = lib.mkMerge [
      (lib.mkOrder 0 ''
        local vim = vim
      '')

      ''
        vim.lsp.enable("nixd")
        vim.opt.exrc = true
        vim.opt.wildmode = "longest:full,full"
      ''
    ];

    plugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
        vim-apathy
        vim-characterize
        vim-easy-align
        vim-nix
        vim-repeat
        vim-sexp
        vim-sexp-mappings-for-regular-people
        vim-unimpaired
        ;
    };

    runtimeDir = [ ./. ];
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
