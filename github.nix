# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ inputs, lib, ... }:
{
  flake.lib = {
    public_inputs = lib.trivial.pipe inputs [
      (lib.attrsets.filterAttrs (n: _: n != "dgx"))
      (lib.attrsets.mapAttrs (_: v: v.outPath))
    ];
  };
}
