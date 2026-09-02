# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.starpls ];

  programs.neovim.initLua = ''
    vim.lsp.enable("starpls")

    vim.filetype.add({
      extension = {
      ipd = "bzl",
      star = "bzl",
      starlark = "bzl",
      },
    })
  '';
}
