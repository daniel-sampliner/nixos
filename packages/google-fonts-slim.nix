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
  version = "0.4.9-unstable-2025-07-04";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "a851626a45d4fcbbd779552f481ca13d0fb9e7bf";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-ydhoDWAI9Sve2GiosK9lO1AV6dTOEDPjADzsMBuBJ38=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
