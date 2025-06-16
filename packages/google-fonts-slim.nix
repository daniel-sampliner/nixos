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
  version = "0.4.9-unstable-2025-06-13";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "8462f38b2da745bbf8b2edc7babb2c35e284ba8c";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-LQuNUEKiKBm7wm8ycQLAwAgfHXD0x2iEdR2bBIIAwYM=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
