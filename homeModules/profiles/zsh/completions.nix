# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs.pkgsExtra) zsh-completions-compiled zsh-xdg-fpath;
  };

  programs.zsh.enableCompletion = true;
  programs.zsh.completionInit = ''
    _week_caching_policy() {
      # rebuild if cache is more than a week old
      local -a oldp
      oldp=( "$1"(Nm+7) )
      (( $#oldp ))
    }

    zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
    zstyle ':completion:*' use-cache on

    autoload -RUz _xdg_fpath_init && _xdg_fpath_init
  '';
}
