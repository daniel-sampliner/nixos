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
  version = "1.11.0";
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
          hash = "sha256-VsRoAM0Mi77WcUt+hr1boe5Hl+fXaTEr5Zh88SAJ9zI=";
        };
        npmDepsHash = "sha256-2fIOfMqz1zK/KOXkrebFiQsTRc8+YotZnwmb0mZxluQ=";
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
