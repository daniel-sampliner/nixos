# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ fetchpatch, pkgs }:
pkgs.wl-clipboard.overrideAttrs (prev: {
  __intentionallyOverridingVersion = true;
  version = "${prev.version}.1.patched";

  patches = prev.patches or [ ] ++ [
    (fetchpatch {
      url = "https://github.com/bugaevc/wl-clipboard/commit/091d6028b5c9db75ad36f9fceb0db3ee718045fa.patch";
      sha256 = "sha256-Ku+qux1cJ70/jOXxsJnbg6aKqCuy4dCUhpqqQQ2rIn0=";
    })
  ];
})
