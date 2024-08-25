# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildPythonPackage,
  fetchPypi,
  lib,
  pythonAtLeast,
  pythonOlder,

  python,
  stdenvNoCC,

  absl-py,
  attrs,
  flatbuffers,
  jax,
  jaxlib,
  matplotlib,
  numpy,
  opencv4,
  protobuf,
  sounddevice,
}:
let
  abi =
    let
      inherit (python) sourceVersion;
    in
    "cp${sourceVersion.major}${sourceVersion.minor}";

  format = "wheel";
  pname = "mediapipe";
  version = "0.10.14";
in
buildPythonPackage {
  pname = "${pname}-bin";
  inherit format version;

  disabled = pythonOlder "3.9" || pythonAtLeast "3.13" || python.implementation != "cpython";

  src = fetchPypi {
    inherit
      abi
      format
      pname
      version
      ;

    dist = abi;
    python = abi;

    platform =
      let
        arch = stdenvNoCC.hostPlatform.linuxArch;
      in
      "manylinux_2_17_${arch}.manylinux2014_${arch}";

    hash = "sha256-qAcygznnNW/aC7FN8S/tvx0zvfgWScX4ZmsAJrHMMLQ=";
  };

  dependencies = [
    absl-py
    attrs
    flatbuffers
    jax
    jaxlib
    matplotlib
    numpy
    opencv4
    protobuf
    sounddevice
  ];

  meta = {
    license = [ lib.licenses.asl20 ];
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };

  passthru.extraLibraryPath = "${python.sitePackages}/mediapipe.libs";
}
