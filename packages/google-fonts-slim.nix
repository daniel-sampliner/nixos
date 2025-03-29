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
  version = "0.4.9-unstable-2025-03-28";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "0e2ffbbdd4498a66f8f3de0a9f99beefe3a03f6c";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-tJVXxMXJN9FWVsvQZOi2gM7qT7e2vrdxKcE+YOpPGjk=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
