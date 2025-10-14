# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  inherit (pkgs.pkgsExtra) fzf-inits;
in
{
  programs.fzf = {
    enable = true;

    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };

  programs.bash.initExtra = lib.mkOrder 200 ''
    if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
      . "${fzf-inits}/share/fzf/shell_init/fzf.bash"
    fi
  '';

  programs.fish.interactiveShellInit = lib.mkOrder 200 ''
    source "${fzf-inits}/share/fzf/shell_init/fzf.fish"
  '';

  programs.zsh.initContent = lib.mkOrder 910 ''
    if [[ $options[zle] = on ]]; then
      . "${fzf-inits}/share/fzf/shell_init/fzf.zsh"
    fi
  '';
}
