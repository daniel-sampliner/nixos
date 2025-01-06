# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, inputs' }:
inputs'.unstable.legacyPackages.sapling.overrideAttrs (prev: {
  passthru = lib.attrsets.filterAttrs (n: _: n != "updateScript") prev.passthru or { };
})
