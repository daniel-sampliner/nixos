# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchurl,
  lib,
  stdenv,
}:

let
  edition = "2024";
  version = "22.00";
  pname = "opentaxsolver_${edition}";
  src = fetchurl {
    url = "mirror://sourceforge/opentaxsolver/OTS_${edition}/v${version}_linux/OpenTaxSolver${edition}_${version}_linux64.tgz";
    hash = "sha256-dPyYNnxbbu1UsZXhpNvL4PNf2UNaqc51GIe6z4q9FaY=";
  };
in
stdenv.mkDerivation {
  inherit pname src version;

  enableParallelBuilding = true;

  sourceRoot = (lib.removeSuffix ".tgz" src.name) + "/src";

  postUnpack = ''
    find "''${sourceRoot:?}/../bin" -type f -delete
    rm "$sourceRoot/../Run_taxsolve_GUI"
  '';

  installPhase = ''
    runHook preInstall

    install -D -t $out/bin ../bin/*

    mkdir -p $out/share/opentaxsolver/src
    cp -r ../tax_form_files $out/share/opentaxsolver
    cp -r formdata $out/share/opentaxsolver/src

    runHook postInstall
  '';

  meta = {
    description = "Calculates income tax form entries, helps do your taxes.";
    homepage = "https://opentaxsolver.sourceforge.net/index.html";
    downloadPage = "https://sourceforge.net/projects/opentaxsolver/";
    license = [ lib.licenses.gpl2 ];
    platforms = lib.platforms.linux;
  };
}
