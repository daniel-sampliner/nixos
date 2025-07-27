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
  version = "0.4.9-unstable-2025-07-25";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "7aef33b3b8d1db561eda7610d8e43fa412d674a2";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-pKE2r+4sSLK7jdZ3pMlxN4f1dtOw8plJERz+A5E0SNo=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
