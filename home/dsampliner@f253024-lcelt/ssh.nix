# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, ... }:
{
  programs.ssh = {
    matchBlocks = {
      "github.com" = {
        extraOptions.PreferredAuthentications = "publickey";
        host = "github.com gist.github.com";
        identitiesOnly = true;
        identityFile = "~/.ssh/github_id_ed25519";
      };
    };
  };
}
