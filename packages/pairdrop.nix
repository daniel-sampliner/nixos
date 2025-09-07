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
  version = "1.11.2";
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
          hash = "sha256-LvrBIdBjb4M2LidEJVCdK2uYydsJY+Cr5eXdfbS46dk=";
        };
        npmDepsHash = "sha256-Ovi5RzWPCVk6LkZ33Anb8abkyu+IrEaCXE/etBgsHYU=";
      }
    );
}).overrideAttrs
  {
    inherit version;
    __intentionallyOverridingVersion = true;

    passthru.updateScript = nix-update-script { };
  }
