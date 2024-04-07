# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ config, lib, ... }:
{
  programs.zsh = {
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      path = "${config.xdg.dataHome}/zsh/history";
      save = 100000;
      share = true;
      size = 110000;
    };

    initExtra =
      let
        options = [
          # Changing Directories
          "AUTO_PUSHD"
          "PUSHD_IGNORE_DUPS"
          "PUSHD_MINUS"

          # Expansion and Globbing
          "EXTENDED_GLOB"
          "NUMERIC_GLOB_SORT"
          "RC_EXPAND_PARAM"

          # History
          "HIST_LEX_WORDS"
          "HIST_NO_STORE"
          "HIST_VERIFY"
          "HIST_REDUCE_BLANKS"

          # Input/Output
          "NO_CLOBBER"
          "INTERACTIVE_COMMENTS"
          "RC_QUOTES"

          # Job Control
          "AUTO_CONTINUE"
          "LONG_LIST_JOBS"

          # Scripts and Functions
          "C_BASES"

          # Shell Emulation
          "APPEND_CREATE"
          "BSD_ECHO"
        ];
      in
      ''
        setOptions() {
          setopt ${lib.escapeShellArgs options}
        }
        setOptions && unfunction setOptions
      '';
  };
}
