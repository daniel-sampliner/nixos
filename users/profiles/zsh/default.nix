# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ config, lib, ... }:
{
  imports = [
    ./completions.nix
    ./contrib.nix
    ./zprof.nix
  ];

  programs.zsh =
    let
      inherit (config.home) homeDirectory;
      dotDir = "${lib.removePrefix "${homeDirectory}/" config.xdg.configHome}/zsh";
    in
    {
      inherit dotDir;

      enable = true;

      envExtra = ''
        setopt NO_GLOBAL_RCS
      '';
    };
}
