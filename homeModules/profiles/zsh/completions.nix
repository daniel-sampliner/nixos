# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
let
  zcompdump_dir = "\${XDG_RUNTIME_DIR:-/run/\${UID:?}}/zsh";
  zcompdump = "${zcompdump_dir}/zcompdump";
in
{
  home.packages = [ pkgs.zsh-completions ];

  programs.zsh.enableCompletion = true;
  programs.zsh.completionInit = ''
    zstyle ':completion:*' cache-path "${zcompdump_dir}"
    zstyle ':completion:*' use-cache on

    . ${./xdg_fpath.zsh}
    _xdg_fpath_hook
  '';

  systemd.user.tmpfiles.rules = [ "d ${config.xdg.cacheHome}/zsh 0700 - - 7d" ];
}
