# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, lib, ... }:
{
  options.wayland.xwayland = {
    enable = lib.mkEnableOption "Xwayland (an X server for interfacing X11 apps with the Wayland protocol)";
  };

  config = {
    wayland.xwayland.enable =
      let
        cfgWM = config.wayland.windowManager;
      in
      lib.mkMerge [
        cfgWM.hyprland.xwayland.enable
        cfgWM.sway.xwayland
      ];
  };
}
