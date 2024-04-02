# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ lib, pkgs, ... }:
{
  environment = {
    interactiveShellInit =
      let
        dircolors-ls-colors = pkgs.runCommand "dircolors-ls-colors" { } ''
          dircolors -b > "$out"
        '';
      in
      ''
        . "${dircolors-ls-colors}"
      '';

    shells = [
      "/run/current-system/sw/bin/dash"
      "${lib.getExe pkgs.dash}"
    ];

    systemPackages = [ pkgs.dash ];
  };

  programs.bash.enableLsColors = false;

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    enableLsColors = false;

    interactiveShellInit = ''
      source "${pkgs.grml-zsh-config}/etc/zsh/zshrc"
    '';

    promptInit = ''
      # Remove right prompt
      zstyle ':prompt:grml:right:setup' items

      # Setup nix shell indicator
      function nix_shell_prompt() {
        REPLY=''${IN_NIX_SHELL+"(nix-shell) "}
      }
      grml_theme_add_token nix-shell-indicator -f nix_shell_prompt '%F{magenta}' '%f'
      zstyle ':prompt:grml:left:setup' items rc nix-shell-indicator change-root user at host path vcs percent
    '';
  };
}
