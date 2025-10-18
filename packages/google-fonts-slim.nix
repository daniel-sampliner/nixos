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
  version = "0.4.9-unstable-2025-10-17";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "601944d2ee97e76d4c456dc3d790db358c0c6ec5";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-Ikej5hf1M4zc96ClI4r92yOMQskduHCeYmxxrtUDyNE=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
