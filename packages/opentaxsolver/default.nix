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
  version = "22.06";
  pname = "opentaxsolver_${edition}";
  src = fetchurl {
    url = "mirror://sourceforge/opentaxsolver/OTS_${edition}/v${version}_linux/OpenTaxSolver${edition}_${version}_linux64.tgz";
    hash = "sha256-SD8JBGk/o6gSM5Zg5FbU0tgy2MgEihfi32quqtgu3SM=";
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

  passthru.updateScript = [ "${builtins.toString ./update}" ];

  meta = {
    description = "Calculates income tax form entries, helps do your taxes.";
    homepage = "https://opentaxsolver.sourceforge.net/index.html";
    downloadPage = "https://sourceforge.net/projects/opentaxsolver/";
    license = [ lib.licenses.gpl2 ];
    platforms = lib.platforms.linux;
  };
}
