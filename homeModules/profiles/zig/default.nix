# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      zig
      zig-shell-completions
      zig-zlint
      zigimports
      zls
      ;
  };

  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.zig-vim;
      config = ''
        vim.g.zig_fmt_parse_errors = 0
        vim.g.zig_fmt_autosave = 0
      '';
    }
    {
      plugin = pkgs.emptyFile;
      runtime."plugin/zls.nvim.lua".source = ./zls.nvim.lua;
    }
  ];
}
