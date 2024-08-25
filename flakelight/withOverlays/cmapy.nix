# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildPythonPackage,
  fetchPypi,
  lib,

  matplotlib,
  numpy,
  opencv4,
}:
let
  pname = "cmapy";
  version = "0.6.6";
in
buildPythonPackage {
  inherit pname version;
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-y1KmswV8SaFG+wlkuDAvL7fWHf5q5t4amLY2qs6AUlU=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "opencv-python" "opencv"

    cat setup.py
  '';

  dependencies = [
    matplotlib
    numpy
    opencv4
  ];

  meta.licenses = [ lib.licenses.mit ];
}
