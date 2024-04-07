# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ lib, ... }:
{
  programs.zsh = {
    envExtra = lib.mkBefore ''
      [[ -v ZPROF ]] && zmodload zsh/zprof
    '';

    initExtra = lib.mkAfter ''
      [[ -v ZPROF ]] && zprof
    '';
  };
}
