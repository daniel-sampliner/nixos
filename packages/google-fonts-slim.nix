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
  version = "0.4.9-unstable-2025-03-04";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "45d35ac1a95cf492a4f787616b9b0efe2412a046";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-gADAFH8kwkQ4N9WOVudCC59psE7IZHKeVcS6bMt8kME=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
