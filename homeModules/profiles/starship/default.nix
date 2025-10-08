# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.pkgsExtra) starship-inits;
  cfg = config.programs.starship;
in
{
  imports = [
    ./format.nix
    ./nerd-fonts.nix
    ./starship-jj.nix
  ];

  home.packages = [ starship-inits ];

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;

    settings = {
      add_newline = false;

      battery.display = [
        {
          threshold = 33;
          style = "bold red";
        }
        {
          threshold = 50;
          style = "yellow";
        }
      ];

      character =
        let
          insert = "[ :;]";
          normal = "[: ;]";
        in
        {
          success_symbol = "${insert}(bold green)";
          error_symbol = "${insert}(bold red)";
          vimcmd_symbol = "${normal}(bold green)";
          vimcmd_replace_one_symbol = "${normal}(bold purple)";
          vimcmd_replace_symbol = "${normal}(bold purple)";
          vimcmd_visual_symbol = "${normal}(bold yellow)";
        };

      cmd_duration = {
        show_notifications = true;
        min_time_to_notify = 30000;
      };

      custom.continuation = {
        command = ./continuation.sh;
        shell = [ "${lib.getExe pkgs.dash}" ];
        style = "bright-black";
        unsafe_no_escape = true;
        use_stdin = false;
        when = true;
      };

      shell = {
        disabled = false;
        style = "white bold dimmed";

        bash_indicator = lib.mkDefault "bsh";
        elvish_indicator = lib.mkDefault "esh";
        fish_indicator = lib.mkDefault "fsh";
        ion_indicator = lib.mkDefault "ion";
        powershell_indicator = lib.mkDefault "psh";
        tcsh_indicator = lib.mkDefault "tsh";
        zsh_indicator = lib.mkDefault "zsh";
      };

      shlvl = {
        disabled = false;
        threshold = 2;
      };
    };
  };

  programs.bash.initExtra = ''
    if [[ $TERM != dumb ]]; then
      . "${starship-inits}/share/starship/shell_init/starship.bash"
      PS2="$(STARSHIP_CONTINUATION=true $(which starship) prompt --continuation)"
    fi
  '';

  programs.fish.${if cfg.enableInteractive then "interactiveShellInit" else "shellInitLast"} = ''
    if test "$TERM" != "dumb"
      source "${starship-inits}/share/starship/shell_init/starship.fish"
      ${lib.optionalString cfg.enableTransience "enable_transience"}
    end
  '';

  programs.zsh.initContent = ''
    if [[ $TERM != dumb ]]; then
      . "${starship-inits}/share/starship/shell_init/starship.zsh"
      PROMPT2="$(STARSHIP_CONTINUATION=true $(which starship) prompt --continuation)"
    fi
  '';

  systemd.user.tmpfiles.rules = [ "d ${config.xdg.cacheHome}/starship 0755 - - 3d" ];
}
