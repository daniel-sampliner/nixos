# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  programs.zsh.initContent = ''
    autoload -RUz edit-command-line && zle -N edit-command-line

    bindkey -M vicmd '#' vi-pound-insert
    bindkey -M vicmd '^g' vi-fetch-history
    bindkey -M vicmd '^v' edit-command-line
    bindkey -M vicmd G end-of-buffer-or-history
  '';
}
