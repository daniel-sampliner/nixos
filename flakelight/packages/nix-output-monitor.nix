# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

{ fetchpatch, nix-output-monitor }:
nix-output-monitor.overrideAttrs (prev: {
  patches = prev.patches or [ ] ++ [
    (fetchpatch {
      url = "https://github.com/maralorn/nix-output-monitor/pull/132.patch";
      hash = "sha256-6uq55PmenrrqVx+TWCP2AFlxlZsYu4NXRTTKYIwRdY4=";
    })
  ];
})
