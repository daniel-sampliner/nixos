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
  version = "0.4.9-unstable-2025-09-12";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "4cfc451a1662aa5911f9ae36bb4753efa5e75ec7";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-TxCVcHGsuFmL0VFWhmg3qaa0A/IuN0xdsCP2kTuFmeM=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
