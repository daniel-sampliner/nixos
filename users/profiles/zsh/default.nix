# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ config, lib, ... }:
let
  inherit (config.home) homeDirectory;
  dotDir = "${lib.removePrefix "${homeDirectory}/" config.xdg.configHome}/zsh";
in
{
  imports = [
    ./completions.nix
    ./contrib.nix
    ./options.nix
    ./zprof.nix
  ];

  home.file =
    let
      files = [
        ".zshenv"
        ".zshrc"
      ];
      mkFile =
        f:
        let
          name = "${dotDir}/${f}";
        in
        {
          inherit name;
          value = {
            onChange = ''
              zsh -f -c 'zcompile -U "${homeDirectory}/${name}"'
            '';
          };
        };
    in
    builtins.listToAttrs (builtins.map mkFile files);

  programs.zsh = {
    inherit dotDir;

    enable = true;

    envExtra = ''
      setopt NO_GLOBAL_RCS
    '';

    initExtra = lib.mkAfter ''
      ttyctl -f
    '';
  };
}
