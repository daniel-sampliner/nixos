# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, lib, ... }:
{
  imports = [
    ./completions.nix
    ./contrib.nix
    ./options.nix
    ./zle.nix
    ./zprof.nix
  ];

  programs.zsh = {
    enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        typeset -axUT CPATH cpath
        typeset -axUT LD_LIBRARY_PATH ld_library_path
        typeset -axUT LIBRARY_PATH library_path
        typeset -axUT MANPATH manpath
        typeset -axUT NIX_PATH nix_path
        typeset -axUT PKG_CONFIG_PATH pkg_config_path
        typeset -axUT XDG_CONFIG_DIRS xdg_config_dirs
        typeset -axUT XDG_DATA_DIRS xdg_data_dirs
      '')

      ''
        PS4='+%1x:%I %1N:%i> '
      ''

      (lib.mkAfter ''
        ttyctl -f
      '')
    ];

    shellGlobalAliases = {
      yolosshopts = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
    };
  };
}
