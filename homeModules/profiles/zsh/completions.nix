# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, ... }:
let
  cacheDir = "${config.xdg.cacheHome}/zsh";
  zcompdump = "${cacheDir}/zcompdump";
in
{
  home.file."${config.programs.zsh.dotDir}/.zshrc".onChange = ''
    $DRY_RUN_CMD rm -f $VERBOSE_ARG -- "${zcompdump}"
  '';

  programs.zsh.enableCompletion = true;
  programs.zsh.completionInit = ''
    zstyle ':completion:*' cache-path "${cacheDir}"
    zstyle ':completion:*' use-cache on

    if autoload -RUz compinit; then
      if [[ ! -s "${zcompdump}" ]]; then compinit -d "${zcompdump}"
      else compinit -C -d "${zcompdump}"
      fi
    fi
  '';

  systemd.user.tmpfiles.rules = [ "D ${cacheDir} 0700 - - 24h" ];
}
