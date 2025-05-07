# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,

  dash,
  execline,
  makeBinaryWrapper,
  stdenvNoCC,
  zig,
}:
stdenvNoCC.mkDerivation {
  pname = "sx";
  version = "0-unstable";
  src = ./.;

  buildInputs = [ execline ];

  nativeBuildInputs = [
    zig
    zig.hook
  ];

  doCheck = true;
  zigBuildFlags = "-Doptimize=Debug";
  zigCheckFlags = "-Doptimize=Debug";

  preCheck = ''
    export XDG_RUNTIME_DIR=/homeless-shelter/run
    export XDG_VTNR=9
  '';

  postCheck = ''
    unset XDG_RUNTIME_DIR XDG_VTNR
  '';
}
