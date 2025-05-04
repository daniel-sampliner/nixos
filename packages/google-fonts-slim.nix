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
  version = "0.4.9-unstable-2025-05-02";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "54bbd6880add9f874368d5c266790d7af9c94b66";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-UPIsQPlJQc+2WhA3Va67frU6zAeE8z8VkQMADYrPCIY=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
