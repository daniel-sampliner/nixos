# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  programs.zsh.initExtra = ''
    autoloadContribs() {
      emulate -L zsh
      setopt ERR_RETURN

      (( $+aliases[run-help] )) && unalias run-help
      autoload -RUz \
        run-help \
        zargs \
        zcalc \
        zmv

      zmodload zsh/mathfunc
    }
    autoloadContribs && unfunction autoloadContribs
  '';
}
