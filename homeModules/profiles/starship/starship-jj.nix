# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  pkg = pkgs.pkgsExtra.starship-jj;
in
{
  home.packages = [ pkg ];

  programs.starship.settings.custom.jj = {
    command = "prompt";
    format = "([$symbol$output]($style) )";
    ignore_timeout = true;

    shell = [
      (lib.getExe pkg)
      "--ignore-working-copy"
      "starship"
    ];

    use_stdin = false;
    when = true;
  };

  xdg.configFile."starship-jj/starship-jj.toml".source =
    (pkgs.formats.toml { }).generate "starship-jj.toml"
      {
        bookmarks = {
          exclude = [ ];
          search_depth = 100;
        };

        module = [
          {
            color = "Blue";
            symbol = " ";
            type = "Symbol";
          }

          {
            behind_symbol = "⇡";
            color = "Magenta";
            separator = " ";
            surround_with_quotes = false;
            type = "Bookmarks";
          }

          {
            empty_text = "∅";
            max_length = 24;
            surround_with_quotes = false;
            type = "Commit";
          }

          {
            conflict = {
              color = "Red";
              disabled = false;
              text = "CONFLICT";
            };
            divergent = {
              color = "Cyan";
              disabled = false;
              text = "DIVERGENT";
            };
            empty = {
              color = "Yellow";
              disabled = false;
              text = "EMPTY";
            };
            hidden = {
              color = "Yellow";
              disabled = false;
              text = "HIDDEN";
            };
            immutable = {
              color = "Yellow";
              disabled = false;
              text = "IMMUTABLE";
            };
            separator = "|";
            type = "State";
          }

          {
            added_lines = {
              color = "Green";
              prefix = "+";
              suffix = "";
            };
            changed_files = {
              color = "Cyan";
              prefix = "";
              suffix = "";
            };
            color = "Magenta";
            removed_lines = {
              color = "Red";
              prefix = "-";
              suffix = "";
            };
            template = "[{changed} {added}{removed}]";
            type = "Metrics";
          }
        ];

        module_separator = "";
        reset_color = true;
        timeout = 500;
      };
}
