# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        inherit pkgs;

        programs = {
          nixfmt.enable = true;

          shfmt = {
            enable = true;
            indent_size = null;
          };

          stylua = {
            enable = true;
            settings = {
              indent_type = "Tabs";
              indent_width = 8;
              sort_requires.enabled = true;
            };
          };

          taplo.enable = true;

          yamlfmt = {
            enable = true;
            settings.formatter = {
              force_quote_style = "double";
              retain_line_breaks_single = true;
              trim_trailing_whitespace = true;
              type = "basic";
            };
          };

          zig.enable = true;
        };

        settings.formatter = {
          shfmt.options = [ "-bn" ];
        };
      };
    };
}
