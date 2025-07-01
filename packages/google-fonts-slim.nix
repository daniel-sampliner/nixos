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
  version = "0.4.9-unstable-2025-06-28";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "cdabad3d0aaec8be8b32e80e5c37c69f03165304";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-ydhoDWAI9Sve2GiosK9lO1AV6dTOEDPjADzsMBuBJ38=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
