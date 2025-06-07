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
  version = "0.4.9-unstable-2025-06-06";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "2b5bd4077bd9269cdf3114266603372af6c3222d";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-qRYvlhC2DxuH/fD3FzD04MM0Uo3jBGOuKFoa81XCoOs=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
