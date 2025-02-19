# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,

  pairdrop,
}:
let
  version = "1.11.1";
in
(pairdrop.override {
  buildNpmPackage =
    args:
    buildNpmPackage (
      args
      // {
        src = fetchFromGitHub {
          owner = "schlagmichdoch";
          repo = "PairDrop";
          rev = "v${version}";
          hash = "sha256-Ovro5vMf28Wz6srEmUYOMFZE746/mcEDcs+f8rG7X+g=";
        };
        npmDepsHash = "sha256-vxH0YmSS3CXOrMQ4Tue8jcwjTZNfiT2Lnhs0O6xrfpQ=";
      }
    );
}).overrideAttrs
  {
    inherit version;

    passthru.updateScript = nix-update-script { };
  }
