# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }: {
  home.packages = builtins.attrValues {
    inherit (pkgs)
      go
      go-tools
      gofumpt
      gopls
      ;
  };

  programs.neovim.runtimeDir = [ ./nvim ];
}
