# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  self',
}:
lib.trivial.pipe ./. [
  (lib.collectDirAttrs {
    default = "test.nix";
    exclude = ./default.nix;
  })

  (builtins.mapAttrs (_: lib.trivial.flip pkgs.callPackage { inherit self'; }))
]
