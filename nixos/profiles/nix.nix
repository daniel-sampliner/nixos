# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;

    optimise.automatic = true;
    optimise.dates = [ "daily" ];

    settings = {
      auto-optimise-store = true;
      keep-outputs = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cuda-maintainers.cachix.org"
        "https://daniel-sampliner.cachix.org"
      ];

      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "daniel-sampliner.cachix.org-1:ADAoo+hx2E7R87SB0xQfD8/uYc+zTl0T/emwDJimOUQ="
      ];
    };

    gc = {
      automatic = true;
      dates = "daily";
      randomizedDelaySec = "6hours";
      persistent = true;
      options = "--delete-older-than 30d";
    };
  };
}
