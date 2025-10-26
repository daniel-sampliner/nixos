# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
let
  pkg = pkgs.pkgsExtra.clustershell-nativessh;
in
{
  home.packages = [ pkg ];
  xdg.configFile.clustershell.source = "${pkg}/etc/clustershell";
}
