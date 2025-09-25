# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  manual.manpages.enable = true;
  programs.home-manager.enable = true;

  home.packages = builtins.attrValues {
    inherit (pkgs)
      age
      coreutils-full
      execline
      eza
      fd
      file
      fzf
      hyperfine
      jq
      less
      man-pages
      man-pages-posix
      nix-output-monitor
      nixfmt-rfc-style
      parallel
      pv
      ripgrep
      rsync
      shellcheck
      shfmt
      sops
      ;
  };

  home.sessionVariables = {
    PAGER = "less";
  };

  xdg.enable = true;
}
