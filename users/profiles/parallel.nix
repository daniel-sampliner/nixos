# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ pkgs, ... }:
{
  home.packages = [ pkgs.parallel ];
  systemd.user.tmpfiles.rules = [
    ''
      d %h/.parallel           0750 - - - -
      f %h/.parallel/will-cite 0640 - - - -
    ''
  ];
}
