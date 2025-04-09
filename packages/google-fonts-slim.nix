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
  version = "0.4.9-unstable-2025-04-08";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "dae941f6edb2564da5fb00cc20cd083f2186221d";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-rBGSzC/b8YuI5dwZa55SGe8JiOGeJKK5Zh0uslqjApw=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
