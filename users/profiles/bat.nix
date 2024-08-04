# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, config, ... }:
let
  pkg = pkgs.bat;

  bat-cache = pkgs.runCommand "bat-cache" { buildInputs = [ pkg ]; } ''
    XDG_CACHE_HOME=$out/share bat cache --build
  '';
in
{
  home.file."${config.xdg.cacheHome}/bat".source = "${bat-cache}/share/bat";
  home.packages = [ pkg ];
}
