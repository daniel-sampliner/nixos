# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

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
