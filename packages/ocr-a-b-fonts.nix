# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchzip,
  lib,
  stdenvNoCC,
}:
let
  version = "0.3.1";
in
stdenvNoCC.mkDerivation {
  pname = "ocr-a-b-fonts";
  inherit version;

  src = fetchzip {
    url = "https://tsukurimashou.org/files/ocr-${version}.zip";
    hash = "sha256-OiQmM9mIpIY5aN0GXT9h4/pQVfvfrG7lKdEwg5VMDbY=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    find . -name '*.otf' -exec \
      install -m 0444 -Dt $out/share/fonts/opentype '{}' +
  '';

  meta.licenses = builtins.attrValues {
    inherit (lib.licenses)
      free # OCR-B
      unfreeRedistributable # OCR-A
      ;
  };
  meta.sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
}
