# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      nixd
      nixfmt
      ;
  };

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
