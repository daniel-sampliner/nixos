# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
  programs.zsh = {
    envExtra = lib.mkOrder 1 ''
      [[ -v ZPROF ]] && zmodload zsh/zprof
    '';

    initExtra = lib.mkOrder 9999 ''
      [[ -v ZPROF ]] && zprof
    '';
  };
}
