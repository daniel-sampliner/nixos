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
          wrapper = pkgs.execline.passthru.writeScript "gnome-terminal-hack-wrapper" "-WS0" ''
            kitty $@
          '';
        in
        pkgs.runCommand "gnome-terminal-hack" { } ''
          install -Dv -- "${wrapper}" "$out/bin/gnome-terminal"
        '';
    in
    [
      gnome-terminal-hack
      pkgs.pkgsExtra.copy-terminfo
    ];

  home.sessionSearchVariables = {
    "TERMINFO_DIRS" = lib.mkBefore [ "/usr/lib64/kitty/terminfo" ];
  };

  programs.git.extraConfig = {
    difftool.kitty.cmd = "kitten diff $LOCAL $REMOTE";
  };

  programs.bash.initExtra = ''
    if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
      export KITTY_SHELL_INTEGRATION=no-rc
      . "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
    fi
  '';

  programs.zsh.initContent = lib.mkOrder 550 ''
    if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
      export KITTY_SHELL_INTEGRATION=no-rc
      autoload -RUz -- "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
      kitty-integration
      unfunction kitty-integration
      fpath=("$KITTY_INSTALLATION_DIR/shell-integration/zsh/completions" $fpath)
    fi
  '';

  xdg.configFile."kitty/kitty.conf".text = ''
    scrollback_lines 20000
    scrollback_fill_enlarged_window yes

    shell_integration no-rc

    resize_draw_strategy size
    resize_in_steps yes
  '';
}
