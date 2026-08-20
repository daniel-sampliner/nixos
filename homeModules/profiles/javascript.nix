# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      deno
      oxfmt
      oxlint
      typescript-go
      ;
  };

  programs.bun.enable = true;

  programs.neovim.initLua = ''
    vim.lsp.enable("denols")
    vim.lsp.enable("oxfmt")
    vim.lsp.enable("oxlint")
    vim.lsp.enable("tsgo")
  '';
}
