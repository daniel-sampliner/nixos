# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchurl,
  passthru,

  s6,
  s6-dns,
  skalibs,
}:
(passthru.prev.s6-networking.override {
  inherit
    s6
    s6-dns
    skalibs
    ;
}).overrideAttrs
  (
    prev:
    let
      version = "2.7.1.0";
      hash = "sha256-p7M0l+cpIaWdTB/GfOXMdL0GXgkQW/Gnnx/HPPmgZZI=";

      src = fetchurl {
        url = builtins.replaceStrings [ prev.version ] [ version ] prev.src.url;
        inherit hash;
      };
    in
    {
      inherit src version;
    }
  )
