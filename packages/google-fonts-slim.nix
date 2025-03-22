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
  version = "0.4.9-unstable-2025-03-20";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "4a8286d1e5ee2b3defb8a7f7847587542f079778";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-HVzGOzuh+UF+k9Cz2qRr/W77O47Ltc6Wntyl87sm6NY=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
