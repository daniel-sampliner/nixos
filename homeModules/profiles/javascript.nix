# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  assertions = [
    {
      assertion = !pkgs ? oxfmt;
      message = "unstable no longer necessary for oxfmt";
    }
  ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      oxlint
      typescript-go
      ;

    inherit (pkgs.pkgsUnstable) oxfmt;
  };

  programs.bun.enable = true;

  programs.neovim.extraLuaConfig = ''
    vim.lsp.enable("oxfmt")
    vim.lsp.enable("oxlint")
    vim.lsp.enable("tsgo")
  '';
}
