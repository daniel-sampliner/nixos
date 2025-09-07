# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  direnv-hooks =
    pkgs.runCommand "direnv-hooks"
      {
        nativeBuildInputs = [
          pkgs.direnv
          pkgs.zsh
        ];
      }
      ''
        mkdir -p $out/share/direnv
        cd $out/share/direnv

        for sh in bash fish zsh; do
          direnv hook "$sh" >hook."$sh"
        done
        zsh -f -c 'zcompile -U hook.zsh'
      '';
  sourceHook = shell: ''
    . "${direnv-hooks}/share/direnv/hook.${shell}"
  '';
in
{
  home.packages = [ pkgs.pigz ];

  home.sessionVariables.DIRENV_LOG_FORMAT =
    let
      ESC = builtins.readFile (pkgs.runCommandLocal "ESC" { } ''echo -ne '\033' >$out'');
    in
    "${ESC}[2mdirenv: %s${ESC}[0m";

  programs = {
    bash.initExtra = lib.mkAfter (sourceHook "bash");
    fish.interactiveShellInit = lib.mkAfter (sourceHook "fish");

    direnv = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
      stdlib = ''
        direnv_layout_dir() {
          echo "''${direnv_layout_dir:-$PWD/.direnv}"
        }
      '';
    };

    git.ignores = [ ".direnv" ];

    zsh.initContent = ''
      ${sourceHook "zsh"}

      ${builtins.readFile ./direnv_completion.zsh}
      autoload -RUz add-zsh-hook
      add-zsh-hook chpwd _direnv_completion_hook
      add-zsh-hook precmd _direnv_completion_hook
    '';
  };

  xdg.configFile."direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
}
