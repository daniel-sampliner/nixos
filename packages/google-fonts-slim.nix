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
  version = "0.4.9-unstable-2025-03-07";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "57442dcf7cccb434e091edbb4589e39d36d923f2";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-WebnHpGZLS0y1BEv9mSVGRtKmzHTF7+jH4g9DS2/Ayc=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
