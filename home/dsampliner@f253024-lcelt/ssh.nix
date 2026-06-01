# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, ... }:
{
  programs.ssh.settings = {
    "github.com gist.github.com" = {
      IdentitiesOnly = true;
      IdentityFile = "~/.ssh/github_id_ed25519";
      PreferredAuthentications = "publickey";
    };
  };
}
