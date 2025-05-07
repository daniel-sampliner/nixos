# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    zig.enable = true;
  };
}
