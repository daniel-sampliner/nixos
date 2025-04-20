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
  version = "0.4.9-unstable-2025-04-18";

  src = fetchFromGitHub {
    owner = "google";
    repo = "fonts";
    rev = "0e70abe31055681b7744b8ea67f579ecda97fc0b";

    sparseCheckout = [ "ofl/adobeblank" ] ++ fonts;

    hash = "sha256-ClAWHaeaB5a+DBA1f/ULdaGzxEE/IiCQRZE8SHxcMR8=";
  };

  postPatch = builtins.replaceStrings [ "rm -rv " ] [ "rm -rfv " ] (prev.postPatch or "");

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
})
