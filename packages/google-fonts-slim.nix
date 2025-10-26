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
  version = "0.4.9-unstable-2025-10-24";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "98e020484fde1171a17950e422424dd8d5a5dbf6";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-7xDBHHI80fSlROQyciKTR11YRT3LFsCBQRuzGn/4NHg=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
