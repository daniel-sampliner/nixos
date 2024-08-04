# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  imports = [
    ./fonts.nix
    ./v4l2loopback.nix
  ];

  gtk.iconCache.enable = true;
  hardware.opengl.enable = true;
}
