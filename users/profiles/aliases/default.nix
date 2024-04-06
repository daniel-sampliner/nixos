# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

_: {
  imports = [ ./colors.nix ];

  home.shellAliases = {
    yolossh = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
  };
}
