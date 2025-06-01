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
  version = "0.4.9-unstable-2025-05-30";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "6f219c35c5116e463728615982cdfa76ef007123";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-oxMB6yeRJNCiCX1MR6O63VkTkKgXs7mWUg12iMdzZw8=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
