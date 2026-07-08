# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      devShells.default = pkgs.mkShellNoCC {
        name = (import ./flake.nix).description;
        inputsFrom = [ config.treefmt.build.devShell ];

        packages = builtins.attrValues {
          inherit (pkgs)
            dix
            home-manager
            nix-output-monitor
            nix-update
            reuse
            ;
        };
      };
    };
}
