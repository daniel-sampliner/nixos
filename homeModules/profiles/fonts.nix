# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [
        "Iosevka"
        "Noto Sans Mono"
        "Symbols Nerd Font Mono"
      ];
      sansSerif = [
        "Noto Sans"
        "Symbols Nerd Font"
      ];
      serif = [
        "Noto Serif"
        "Symbols Nerd Font"
      ];
    };
  };

  xdg.dataFile.fonts = {
    source =
      let
        fontsEnv = pkgs.buildEnv {
          name = "fonts-env";

          paths = builtins.attrValues {
            inherit (pkgs)
              atkinson-hyperlegible-next
              iosevka-bin
              ;

            inherit (pkgs.nerd-fonts) symbols-only;
            inherit (pkgs.pkgsExtra) ocr-a-b-fonts;
          };

          pathsToLink = [ "/share/fonts" ];
        };
      in
      "${fontsEnv}/share/fonts";
  };

  home.sessionVariables = {
    LESSUTFCHARDEF = "e000-f8ff:p,f0001-fffff:p";
  };
}
