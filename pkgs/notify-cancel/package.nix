# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  gitMinimal,
  lib,
  pkg-config,
  stdenv,
  systemdLibs,
  zig,
}:
stdenv.mkDerivation {
  pname = "notify_cancel";

  version = lib.pipe ./build.zig.zon [
    builtins.readFile
    (lib.strings.splitString "\n")
    (builtins.map (builtins.match ''.*\.version = "([0-9]+(\.[0-9]+){2})[^"]*".*''))
    (lib.lists.findFirst builtins.isList (throw "could not parse version from build.zig.zon"))
    builtins.head
  ];

  src = ./.;

  nativeBuildInputs = [
    gitMinimal
    pkg-config
    zig.hook
  ];
  buildInputs = [ systemdLibs ];

  meta.mainProgram = "notify_cancel";
}
