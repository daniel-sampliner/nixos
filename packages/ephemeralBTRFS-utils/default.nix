# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  makeBinaryWrapper,
  stdenvNoCC,

  btrfs-progs,
  coreutils,
  dash,
  gnugrep,
}:
let
  pname = "ephemeralBTRFS-utils";

  runtimeInputs = [
    btrfs-progs
    coreutils
    gnugrep
  ];
in
stdenvNoCC.mkDerivation {
  inherit pname;
  version = "0.0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.union ./ephemeral-btrfs-nuke-root ./ephemeral-btrfs-root-diff;
  };

  buildInputs = [ dash ] ++ runtimeInputs;
  nativeBuildInputs = [ makeBinaryWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dt $out/bin *

    runHook postInstall
  '';

  postFixup = ''
    for b in $out/bin/*; do
      if [[ -x $b ]]; then
        wrapProgram "$b" --suffix PATH : ${lib.makeBinPath runtimeInputs}
      fi
    done
  '';

  meta.license = lib.licenses.agpl3Plus;
}
