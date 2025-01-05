# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  stdenv,
  writers,

  gtk2,
  gtk3,
  opentaxsolver,
  pkg-config,

  useGTK3 ? false,
}:
let
  populate_ots_data = writers.writeExecline { } "/bin/populate-ots-data" ''
    define base "${opentaxsolver}/share/opentaxsolver"
    if { cp -r "''${base}/src" "''${base}/tax_form_files" . }
    ln -s "${lib.getExe' opentaxsolver "universal_pdf_file_modifier"}" .
  '';

  mainProgram = if useGTK3 then "ots_gui3" else "ots_gui2";
in
stdenv.mkDerivation {
  pname = builtins.replaceStrings [ "opentaxsolver_" ] [ "opentaxsolver_gui_" ] opentaxsolver.pname;
  inherit (opentaxsolver)
    postUnpack
    sourceRoot
    src
    version
    ;

  buildInputs = if useGTK3 then [ gtk3 ] else [ gtk2 ];
  nativeBuildInputs = [ pkg-config ];

  enableParallelBuilding = true;

  buildFlags = [
    "-C"
    "Gui_gtk"
    "-f"
    (if useGTK3 then [ "make_gtk3" ] else "makefile")
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    mkdir -p "$out/share/opentaxsolver"
    ln -st "$out/bin" "${opentaxsolver}/bin/"*
    ln -st "$out/share/opentaxsolver" "${opentaxsolver}/share/opentaxsolver/"*

    install -Dt "$out/bin" ../bin/* "${lib.getExe populate_ots_data}"

    runHook postInstall
  '';

  meta = opentaxsolver.meta // {
    inherit mainProgram;
  };
}
