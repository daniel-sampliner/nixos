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
  version = "0.4.9-unstable-2025-02-21";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "c6fb1923767debf61398eedb7f64ea54a15eca58";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-7+SlnYKMYII57wqm+twsxAmz6n5D71l4NpHH5asJC40=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
