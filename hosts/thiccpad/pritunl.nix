# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
let
  pkg = pkgs.pritunl-client;
in
{
  environment.persistence.${config.boot.ephemeral.store}.directories = [ "/var/lib/pritunl-client" ];
  environment.systemPackages = [ pkg ];
  systemd.packages = [ pkg ];
}
