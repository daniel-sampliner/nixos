# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  programs.ssh = {
    matchBlocks = {
      "github.com" = {
        extraOptions.PreferredAuthentications = "publickey";
        identitiesOnly = true;
        identityFile = "~/.ssh/github_id_ed25519";
      };
    };
  };
}
