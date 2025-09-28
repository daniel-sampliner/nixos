# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
let
  inherit (pkgs.pkgsExtra) mise-inits;
in
{
  home.packages = [ pkgs.xxHash ];
  programs = {
    mise = {
      enable = true;
      package = pkgs.pkgsUnstable.mise;

      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;

      globalConfig.settings = {
        disable_backends = [ "asdf" ];
        paranoid = true;

        status = {
          missing_tools = "always";
          show_env = true;
          show_tools = true;
        };
      };
    };

    git.ignores = [
      ".mise-nix-devshell"
      "mise.local.toml"
    ];

    bash.initExtra = ''
      . ${mise-inits}/share/mise/shell_init/mise.bash
    '';

    fish.interactiveShellInit = ''
      source ${mise-inits}/share/mise/shell_init/mise.fish
    '';

    zsh.initContent = ''
      . ${mise-inits}/share/mise/shell_init/mise.zsh
    '';
  };

  xdg.dataFile."mise/plugins/nix-devshell".source = ./nix-devshell;
}
