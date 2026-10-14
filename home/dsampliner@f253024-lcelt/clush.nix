# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
let
  pkg = pkgs.python3Packages.clustershell;
in
{
  home.packages = [ pkg ];
  xdg.configFile.clustershell.source = "${pkg}/etc/clustershell";
}
