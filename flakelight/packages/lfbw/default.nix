# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ fetchFromGitHub, python3Packages }:
let
  repo = "Linux-Fake-Background-Webcam";
  pname = "lfbw";
in
python3Packages.buildPythonApplication {
  inherit pname;
  version = "0-unstable-2024-05-25";

  src = fetchFromGitHub {
    inherit repo;
    owner = "fangfufu";
    rev = "ff34f6bddabcc03a1f2320c596d44a87e3f9f84f";
    hash = "sha256-QawqIcp1TVf0rtf4RPwEVB6Znr4Wu4DDNI/tjMPcT6Y=";
  };

  patches = [ ./deps.patch ];

  postPatch = ''
    export shareDir=$out/share/${pname}
    substituteInPlace lfbw/lfbw.py \
      --replace-fail '"foreground.jpg"' '"'"$shareDir/foreground.jpg"'"' \
      --replace-fail '"background.jpg"' '"'"$shareDir/background.jpg"'"'
  '';

  postInstall = ''
    install  -Dm0644 -t "$shareDir" foreground.jpg background.jpg
  '';

  pyproject = true;
  build-system = [ python3Packages.poetry-core ];
  dependencies = builtins.attrValues {
    inherit (python3Packages)
      configargparse
      cmapy
      inotify-simple
      mediapipe
      numpy
      opencv4
      protobuf
      pyfakewebcam
      ;
  };

  makeWrapperArgs =
    let
      inherit (python3Packages) mediapipe;
    in
    [
      "--prefix"
      "LD_LIBRARY_PATH"
      ":"
      "${mediapipe}/${mediapipe.passthru.extraLibraryPath}"
    ];
}
