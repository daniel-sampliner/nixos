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
  version = "0.4.9-unstable-2025-03-26";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "ee3eba1f6a6be09d71d688f0e2f4b27f2c795c42";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-5qTn84sM7DhVOwOhaRV2A4zrVz4h78L2PtZU+7+xw+g=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
