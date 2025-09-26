# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  imports = [
    ./colors.nix
  ];

  home.shellAliases = {
    yolossh = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
    fastrandom = "openssl enc -aes-256-ctr -pass file:<(xxd -l 128 -p /dev/urandom | tr -d '[:space:]') -nosalt 2>/dev/null </dev/zero";
  };
}
