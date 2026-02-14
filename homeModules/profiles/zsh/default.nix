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
    dotDir = "${config.xdg.configHome}/zsh";

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        typeset -aUT NIX_PATH nix_path
        typeset -aUT XDG_DATA_DIRS xdg_data_dirs
        typeset -aUT XDG_CONFIG_DIRS xdg_config_dirs
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
