# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
  programs.zsh = {
    envExtra = lib.mkOrder 0 ''
      if [[ -n $ZPROF ]]; then zmodload zsh/zprof; fi
    '';

    initContent = lib.mkOrder 9999 ''
      if [[ -n $ZPROF ]]; then zprof; fi
    '';
  };
}
