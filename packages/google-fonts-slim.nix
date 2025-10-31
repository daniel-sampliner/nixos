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
  version = "0.4.9-unstable-2025-10-30";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "1a4c4b3930ddc479b9a8eff78f8567ca0b3e4ca6";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-TLjxISZZhlnvPhNmfhf9wX5vTd0tPX594Ocrxyt+Q8w=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
