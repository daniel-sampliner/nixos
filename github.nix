# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ inputs, lib, ... }:
{
  flake.lib = {
    public_input_paths = lib.trivial.pipe inputs [
      (lib.attrsets.filterAttrs (n: _: n != "dgx"))
      (lib.attrsets.mapAttrsToList (_: v: v.outPath))
    ];
  };
}
