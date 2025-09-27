# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt = {
    programs = {
      nixfmt.enable = true;

      stylua = {
        enable = true;
        settings = {
          indent_type = "Tabs";
          indent_width = 8;
          sort_requires.enabled = true;
        };
      };
    };
  };
}
