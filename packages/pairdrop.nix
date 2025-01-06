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
  version = "1.10.10";
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
          hash = "sha256-urkCLZ6Vwje/F9f+QZswFigzYYVUkG5I4UmO1FmBaU0=";
        };
        npmDepsHash = "sha256-n19pqG8gHRaFH3GnKfyhqq7U1EdQUlzxeXrrQY8Fkf0=";
      }
    );
}).overrideAttrs
  (prev: {
    inherit version;

    installPhase = builtins.replaceStrings [ "index.js" ] [ "server/index.js" ] (
      prev.installPhase or ""
    );

    passthru.updateScript = nix-update-script { };
  })
