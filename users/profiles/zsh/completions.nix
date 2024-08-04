# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, lib, ... }:
{
  home.activation.deleteZSHCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -v oldGenPath || "$oldGenPath" != "$newGenPath" ]]; then
      $DRY_RUN_CMD rm -f $VERBOSE_ARG -- "${config.home.homeDirectory}/${config.programs.zsh.dotDir}/.zcompdump"
    fi
  '';

  programs.zsh = {
    enableCompletion = true;

    completionInit = ''
      initCompletion() {
        emulate -L zsh
        setopt ERR_RETURN

        autoload -RUz compinit
        if [[ ! -s "$ZDOTDIR/.zcompdump" ]]; then
          compinit
          zcompile -U "$ZDOTDIR/.zcompdump"
        else
          compinit -C
        fi
      }
      initCompletion && unfunction initCompletion
    '';
  };
}
