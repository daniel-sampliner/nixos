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
  version = "0.4.9-unstable-2025-05-01";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "9483a03c1f71dfc4fa89ca492613e1d8116b6d28";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-UPIsQPlJQc+2WhA3Va67frU6zAeE8z8VkQMADYrPCIY=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
