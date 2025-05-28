# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchurl,
  passthru,

  skalibs,
}:
(passthru.prev.s6-dns.override { inherit skalibs; }).overrideAttrs (
  prev:
  let
    version = "2.4.1.0";
    hash = "sha256-tjCFGfEJpnRpxKqvqd8fAJrQlh+nmP/Dj4lVh+aTVyk=";

    src = fetchurl {
      url = builtins.replaceStrings [ prev.version ] [ version ] prev.src.url;
      inherit hash;
    };
  in
  {
    inherit src version;
  }
)
