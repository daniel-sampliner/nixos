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
  version = "0.4.9-unstable-2025-07-18";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "6526fad630c078afb8bfb134f2efc77f2ccd7d17";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-pKE2r+4sSLK7jdZ3pMlxN4f1dtOw8plJERz+A5E0SNo=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
