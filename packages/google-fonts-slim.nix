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
  version = "0.4.9-unstable-2025-02-28";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "dc7674ef8f83d06d1aa59c09f14e7019233ff9d3";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-FFh90I0Od95E4+cK/22B2+O2hT0KYbzfLrBq7ygV05s=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
