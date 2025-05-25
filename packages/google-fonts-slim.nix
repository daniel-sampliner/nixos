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
  version = "0.4.9-unstable-2025-05-23";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "c781e48f571fe26740a9814c0461064628cbd175";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-whL/bu86/CcG9w69fjs5uDZmSG0smGF2ZAS3fXArhZA=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
