# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  imports = [ ./colors.nix ];

  home.shellAliases = {
    yolossh = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
  };
}
