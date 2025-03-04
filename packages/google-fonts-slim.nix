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
  version = "0.4.9-unstable-2025-03-03";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "7f97a25bcfec6a6eacc6138bc2b5c39378fe2222";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-gADAFH8kwkQ4N9WOVudCC59psE7IZHKeVcS6bMt8kME=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
