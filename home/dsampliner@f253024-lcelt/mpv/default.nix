# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.user.tmpfiles.rules = [
    "L+ ${config.xdg.configHome}/jellyfin-mpv-shim/scripts/mpris.so - - - - /usr/lib64/mpv/mpris.so"
  ];

  xdg.configFile =
    let
      script = ./kde-nightlight-inhibit.lua;
    in
    lib.trivial.pipe
      [ "jellyfin-mpv-shim" "mpv" ]
      [
        (builtins.map (
          d: lib.attrsets.nameValuePair "${d}/scripts/${builtins.baseNameOf script}" { source = script; }
        ))
        builtins.listToAttrs
      ];
}
