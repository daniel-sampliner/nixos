# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, ... }:
{
  dgx.mc-ssh-configs = "${config.home.homeDirectory}/projects/nvidia/mc-ssh-configs";

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
