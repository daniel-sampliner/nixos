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
  version = "0.4.9-unstable-2025-05-16";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "973a8934ba60f3a32a83617dce24edc3605fe3bb";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-KJGVcrq5fiqWmCrXOU9RRMBTtPkJl3HiNQLyhoUIr6g=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
