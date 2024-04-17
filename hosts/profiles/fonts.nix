# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
{
  fonts = {
    enableDefaultPackages = true;
    enableGhostscriptFonts = true;
    fontDir.enable = true;
    fontDir.decompressFonts =
      config.programs.xwayland.enable
      || lib.pipe config.home-manager.users [
        builtins.attrValues
        (builtins.map (u: u.wayland.xwayland.enable))
        (lib.any lib.id)
      ];

    fontconfig.defaultFonts =
      let
        withFallbackSymbols = f: f ++ [ "Symbols Nerd Font" ];
      in
      {
        monospace = withFallbackSymbols [ "Iosevka Term" ];
        sansSerif = withFallbackSymbols [ "DejaVu Sans" ];
        serif = withFallbackSymbols [ "DejaVu Serif" ];
      };

    packages = [
      pkgs.iosevka-bin
      (pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    ];
  };
}
