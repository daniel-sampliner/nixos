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
  config.home.packages = lib.mkIf config.programs.home-manager.enable [
    pkgs.inputs'.home-manager.packages.default
  ];
}
