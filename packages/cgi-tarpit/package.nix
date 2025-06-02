# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  callPackage,
  lib,
  pkgsUnstable,
  runCommand,
  stdenvNoCC,

  zig,
  zon2nix,
}:
let
  pname = "cgi-tarpit";
in
stdenvNoCC.mkDerivation {
  inherit pname;
  version = "0-unstable";
  src = ./.;

  nativeBuildInputs = [
    zig
    zig.hook
    zon2nix
  ];

  postPatch = ''
    ln -sv ${callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
  '';

  doCheck = true;
}
