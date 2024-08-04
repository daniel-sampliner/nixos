# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
{
  home.packages = builtins.attrValues { inherit (pkgs) asdf-vm groff patchelf-auto-interp; };

  home.sessionVariables = rec {
    ASDF_CONFIG_FILE = "${config.xdg.configHome}/asdfrc";
    ASDF_DATA_DIR = "${config.xdg.dataHome}/asdf";
  };

  xdg.configFile."direnv/lib/use_asdf.sh".source = ./use_asdf.sh;
}
