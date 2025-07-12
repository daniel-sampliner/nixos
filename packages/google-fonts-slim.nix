# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitHub,
  nix-update-script,

  google-fonts,
}:
let
  fonts = [
    "ofl/atkinsonhyperlegiblemono"
    "ofl/atkinsonhyperlegiblenext"
  ];
in
google-fonts.overrideAttrs (prev: {
  pname = google-fonts.pname + "-slim";
  version = "0.4.9-unstable-2025-07-11";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "0e6467f2e3338b512862170368e48c8393564be1";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-wQSsDSI7nP0jq5EmjbCfRdFD6Gr0n0YSYPIrsijV800=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
