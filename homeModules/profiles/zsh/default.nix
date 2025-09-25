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

    initContent = lib.mkAfter ''
      ttyctl -f
    '';

    dotDir = ".config/zsh";
  };
}
