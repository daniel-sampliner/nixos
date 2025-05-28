# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchurl,
  passthru,
}:
passthru.prev.skalibs.overrideAttrs (
  prev:
  let
    version = "2.14.4.0";
    hash = "sha256-DmJiYYSMySBzj5L9UKJMFLIeMDBt/tl7hDU2n0uuAKU=";

    src = fetchurl {
      url = builtins.replaceStrings [ prev.version ] [ version ] prev.src.url;
      inherit hash;
    };
  in
  {
    inherit version src;
  }
)
