# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, lib, ... }:
{
  imports = [
    ./completions.nix
    ./contrib.nix
    ./options.nix
    ./zprof.nix
  ];

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        typeset -aUT XDG_DATA_DIRS xdg_data_dirs
        typeset -aUT XDG_CONFIG_DIRS xdg_config_dirs
      '')

      (lib.mkAfter ''
        ttyctl -f
      '')
    ];

    shellGlobalAliases = {
      yolosshopts = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
    };
  };
}
