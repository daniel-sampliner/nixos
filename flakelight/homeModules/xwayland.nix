# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

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
