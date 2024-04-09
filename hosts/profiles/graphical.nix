# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

_: {
  imports = [ ./v4l2loopback.nix ];
  hardware.opengl.enable = true;
}
