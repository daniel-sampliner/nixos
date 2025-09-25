# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      devshells.default = {
        motd = "";
        name = (import ./flake.nix).description;

        packagesFrom = [
          config.treefmt.build.devShell
        ];

        packages = builtins.attrValues {
          inherit (pkgs)
            home-manager
            nix-output-monitor
            reuse
            ;
        };
      };
    };
}
