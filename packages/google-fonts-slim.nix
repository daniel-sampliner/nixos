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
  version = "0.4.9-unstable-2025-04-10";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "7d1c962b6fbc8987b59ed229bbe5c12764d3a624";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-ET5C7c2Zxde5Op3Yw/PwzxAALIgzv66p/19mbBF2wcQ=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
