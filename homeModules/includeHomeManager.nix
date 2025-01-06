# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.home.packages = lib.mkIf config.programs.home-manager.enable [
    pkgs.inputs'.home-manager.packages.default
  ];
}
