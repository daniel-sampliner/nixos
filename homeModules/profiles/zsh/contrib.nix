# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  programs.zsh.initContent = ''
    if (( $+aliases[run-help] )); then unalias run-help; fi
    autoload -RUz \
      run-help \
      zargs \
      zcalc \
      zmv \
    ;
  '';
}
