# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchurl,
  lib,
  stdenv,
  gtk3,
  pkg-config,
  guiSupport ? false,
}:

let
  edition = "2023";
  version = "21.06";
  pname = "opentaxsolver_${lib.optionalString guiSupport "gui_"}${edition}";
  src = fetchurl {
    url = "mirror://sourceforge/opentaxsolver/OTS_${edition}/v${version}_linux/OpenTaxSolver${edition}_${version}_linux64.tgz";
    hash = "sha256-dvainYJK0yKVVfBMe/kcdv6NFr24IsMfa0EEgNlIqQs=";
  };
in
stdenv.mkDerivation {
  inherit pname src version;

  nativeBuildInputs = lib.optionals guiSupport [ pkg-config ];
  buildInputs = lib.optionals guiSupport [ gtk3 ];

  enableParallelBuilding = true;

  sourceRoot = (lib.removeSuffix ".tgz" src.name) + "/src";

  patchFlags = [ "-p2" ];
  patches = lib.optionals guiSupport [ ./make-gui.patch ];

  postUnpack = ''
    (
      set -e
      cd "''${sourceRoot:?}/../bin"
      find . -type f -delete
    )
  '';

  installPhase = ''
    runHook preInstall

    install -D -t $out/bin ../bin/*

    cp -r ../tax_form_files $out
    mkdir -p $out/src
    cp -r formdata $out/src

    runHook postInstall
  '';

  meta = {
    description = "Calculates income tax form entries, helps do your taxes.";
    homepage = "https://opentaxsolver.sourceforge.net/index.html";
    downloadPage = "https://sourceforge.net/projects/opentaxsolver/";
    license = [ lib.licenses.gpl2 ];
    platforms = lib.platforms.linux;

    mainProgram =
      assert lib.assertMsg guiSupport "${pname} has no mainProgram, use getExe' instead of getExe";
      "ots_gui3";
  };
}
