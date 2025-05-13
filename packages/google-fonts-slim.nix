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
  version = "0.4.9-unstable-2025-05-12";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "762f2682a0668c41d78647326c76622b926bfda8";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-bzi0MKoFz1f3qHzdBE0rtVPLcBvw6I5Cxctz1ju5X4Q=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
