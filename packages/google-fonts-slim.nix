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
  version = "0.4.9-unstable-2025-09-05";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "6c1851dd804942011fb83b17dddb4f28f8fd25ba";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-ZUxBZunxF37lgjcHiJ3VhIZS2/OA/gqU4RR1ir2NWNc=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
