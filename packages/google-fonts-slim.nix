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
  version = "0.4.9-unstable-2025-06-16";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "1ade59d088239e9aa38f7678e3a5efd9e4d5c70d";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-LQuNUEKiKBm7wm8ycQLAwAgfHXD0x2iEdR2bBIIAwYM=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
