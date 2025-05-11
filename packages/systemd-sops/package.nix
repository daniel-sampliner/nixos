# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  stdenv,

  age,
  makeBinaryWrapper,
  sops,
  zig,
}:
let
  pname = "systemd-sops";
in
stdenv.mkDerivation {
  inherit pname;
  version = "0-unstable";

  src = ./.;

  nativeBuildInputs = [
    zig
    zig.hook
  ];

  nativeCheckInputs = [
    age
    sops
  ];

  doCheck = true;
  meta.mainProgram = "systemd-sops";
}
