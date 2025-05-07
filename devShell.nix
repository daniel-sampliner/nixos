# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  self',
}:
pkgs.devshell.mkShell {
  devshell = {
    motd = "";
    name = (import ./flake.nix).description;

    packages = builtins.attrValues {
      inherit (pkgs)
        nix-eval-jobs
        nix-fast-build
        nix-output-monitor
        nix-update

        reuse
        ;

      inherit (self') formatter;
    };
  };
}
