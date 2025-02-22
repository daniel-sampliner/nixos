# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  stdenv,

  makeBinaryWrapper,
  sops,
  zig,
}:
let
  pname = "systemd-sops";
in
stdenv.mkDerivation {
  inherit pname;
  version = "0.0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.difference ./. ./default.nix;
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    zig
    zig.hook
  ];

  postInstall = ''
    wrapProgram "$out/bin/${pname}" --suffix PATH : "${lib.makeBinPath [ sops ]}"
  '';

  doCheck = true;
}
