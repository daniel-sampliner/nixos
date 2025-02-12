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
  version = "1.10.11";
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
          hash = "sha256-H3XfLBxJZaHzCBnGUKY92EL3ES47IgXkTOUr8zY1sIY=";
        };
        npmDepsHash = "sha256-CYVcbkpYgY/uqpE5livQQhb+VTMtCdKalUK3slJ3zdQ=";
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
