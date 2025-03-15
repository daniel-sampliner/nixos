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
  version = "0.4.9-unstable-2025-03-14";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "b37bc6885473c00382fc270e5698badebdb3d80b";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-QA8GTSi3kvuHE6DeqKhHXj23BDnqOhoazpxrt6eXKak=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
