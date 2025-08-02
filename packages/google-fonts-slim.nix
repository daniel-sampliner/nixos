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
  version = "0.4.9-unstable-2025-08-01";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "96ea36719d46965fb25755b833a341a2f5becd28";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-5ROCZmYclIk0pJVz9Rv+hcYlyVdoXHhJWFzD4JxJ3OY=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
