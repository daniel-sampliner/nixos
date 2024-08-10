# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ augeas }:
augeas.overrideAttrs (prev: {
  patches = prev.patches or [ ] ++ [ ./dnsmasq-key-optional-space.patch ];
})
