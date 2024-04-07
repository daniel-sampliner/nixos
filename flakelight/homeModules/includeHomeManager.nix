# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  flake,
  lib,
  ...
}:
{
  config.home.packages = lib.mkIf config.programs.home-manager.enable [
    flake.inputs'.home-manager.packages.default
  ];
}
