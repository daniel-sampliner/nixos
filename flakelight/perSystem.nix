# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pkgs:
let
  inherit (pkgs)
    lib
    system

    outputs'
    ;
in
{
  github = {
    checks = lib.pipe outputs'.checks [
      builtins.attrNames
      (builtins.filter (n: !lib.hasPrefix "containers-" n))
      (builtins.filter (n: !lib.hasPrefix "nixos-" n))
      (builtins.map (n: ".#checks.${system}.${n}"))
    ];

    containers = lib.pipe outputs'.containers [
      builtins.attrNames
      (builtins.map (n: ".#containers.${system}.${n}"))
    ];
  };
}
