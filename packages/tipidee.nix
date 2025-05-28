# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchurl,
  passthru,
  skalibs,
}:
(passthru.prev.tipidee.override { inherit skalibs; }).overrideAttrs (
  prev:
  let
    version = "0.0.6.0";
    hash = "sha256-4q3YvhCJAi43kCQbk6xKWj5Y2tZF9dkZ+MunRM1KFwI=";

    src = fetchurl {
      url = builtins.replaceStrings [ prev.version ] [ version ] prev.src.url;
      inherit hash;
    };
  in
  {
    inherit src version;
  }
)
