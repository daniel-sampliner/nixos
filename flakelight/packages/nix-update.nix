# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: MIT

{ fetchpatch, nix-update }:
nix-update.overrideAttrs (prev: {
  patches = prev.patches or [ ] ++ [
    (fetchpatch {
      url = "https://github.com/Mic92/nix-update/pull/239.patch";
      hash = "sha256-gAdUdffNrJatSuefcASWCHOYELnn+SAVsWGBxb26vCE=";
    })
  ];
})
