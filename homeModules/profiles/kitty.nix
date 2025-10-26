# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
{
  home.packages =
    let
      # glib has hardcoded list of terminals that it will attempt to use for
      # launching terminal applications:
      #
      #   https://gitlab.gnome.org/GNOME/glib/-/blob/2.73.3/gio/gdesktopappinfo.c#L2657
      #
      # We can force kitty to be used instead by simply symlinking it as
      # "gnome-terminal"
      gnome-terminal-hack =
        let
          script = pkgs.execline.passthru.writeScript "gnome-terminal-hack-wrapper" "-WS0" ''
            kitty $@
          '';
        in
        pkgs.runCommand "gnome-terminal-hack" { } ''
          install -Dv -- "${script}" "$out/bin/gnome-terminal"
        '';
    in
    [
      gnome-terminal-hack
      pkgs.pkgsExtra.copy-terminfo
    ];

  programs.kitty = {
    enable = true;
    enableGitIntegration = false;

    font = {
      package = pkgs.iosevka-bin;
      name = "Iosevka Term Light";
    };

    keybindings = {
      "ctrl+shift+n" = "new_os_window_with_cwd";
    };

    settings = {
      disable_ligatures = "cursor";

      scrollback_lines = 20000;
      scrollback_fill_enlarged_window = "yes";

      initial_window_height = "43c";
      initial_window_width = "132c";
      remember_window_size = "no";
      resize_in_steps = "yes";
    };
  };

  programs.git.extraConfig = {
    difftool.kitty = {
      cmd = "kitten diff $LOCAL $REMOTE";
      prompt = false;
    };
  };

  programs.jujutsu.settings = {
    merge-tools.kitten = {
      program = "kitten";
      edit-args = [ ];

      diff-args = [
        "diff"
        "$left"
        "$right"
      ];
    };
  };

  xdg.configFile."kitty/ssh.conf".text = ''
    shell_integration enabled
  '';
}
