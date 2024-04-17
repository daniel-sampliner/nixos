# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.kitty;
in
{
  home.packages = [
    # glib has hardcoded list of terminals that it will attempt to use for
    # launching terminal applications:
    #
    #   https://gitlab.gnome.org/GNOME/glib/-/blob/2.73.3/gio/gdesktopappinfo.c#L2657
    #
    # We can force kitty to be used instead by simply symlinking it as
    # "gnome-terminal"
    (pkgs.runCommandLocal "gnome-terminal-hack" { } ''
      mkdir -p $out/bin
      ln -s ${lib.getExe cfg.package} "$out/bin/gnome-terminal"
    '')
  ];
  programs.kitty = {
    enable = true;

    settings = {
      scrollback_fill_enlarged_window = "yes";
      scrollback_lines = 20000;

      resize_draw_strategy = "size";
      resize_in_steps = "yes";
    };
  };
}
