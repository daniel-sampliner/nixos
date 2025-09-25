# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, ... }:
{
  programs.zsh.history = {
    expireDuplicatesFirst = true;
    extended = true;
    ignoreDups = true;
    ignoreSpace = true;
    path = "${config.xdg.dataHome}/zsh/zsh_history";
    save = 100000;
    share = true;
    size = 110000;
  };

  programs.zsh.initContent = ''
    setopt \
      AUTO_PUSHD \
      PUSHD_IGNORE_DUPS \
      PUSHD_MINUS \
    ;

    setopt \
      EXTENDED_GLOB \
      NO_NOMATCH \
      NUMERIC_GLOB_SORT \
      RC_EXPAND_PARAM \
    ;

    setopt \
      HIST_NO_STORE \
      HIST_VERIFY \
    ;

    setopt \
      NO_CLOBBER \
      INTERACTIVE_COMMENTS \
      RC_QUOTES \
    ;

    setopt \
      AUTO_CONTINUE \
      LONG_LIST_JOBS \
    ;

    setopt \
      APPEND_CREATE \
      BSD_ECHO \
    ;
  '';
}
