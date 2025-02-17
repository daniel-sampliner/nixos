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
  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "fc541cab9a1a6991ffb4718382d33e4281dd48c1";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-7+SlnYKMYII57wqm+twsxAmz6n5D71l4NpHH5asJC40=";
  };
  version = "0.4.9-unstable-2025-02-16";

  postPatch = builtins.replaceStrings [ "rm " ] [ ": rm" ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
