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
  version = "0.4.9-unstable-2025-10-10";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "11ca86e3b176fe1fff5ca8450c7e6f2fbee46fb5";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-6NYEK5ljVjk11FdL/t97sPw2izeRLhBR2/B/3lVVsRM=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
