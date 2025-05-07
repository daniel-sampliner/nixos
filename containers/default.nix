# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
}:
lib.trivial.pipe ./. [
  (lib.collectDirAttrs {
    exclude = ./default.nix;
  })

  (builtins.mapAttrs (_: lib.trivial.flip pkgs.callPackage { }))
]
