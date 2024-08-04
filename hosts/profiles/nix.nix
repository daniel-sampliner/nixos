# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;

    optimise.automatic = true;
    optimise.dates = [ "daily" ];
    settings.auto-optimise-store = true;

    gc = {
      automatic = true;
      dates = "daily";
      randomizedDelaySec = "6hours";
      persistent = true;
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
    '';
  };

  systemd.services.nix-gc.unitConfig.ConditionACPower = true;
  systemd.services.nix-optimise.unitConfig.ConditionACPower = true;
}
