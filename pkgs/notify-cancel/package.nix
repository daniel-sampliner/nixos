# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  pkg-config,
  stdenv,
  systemdLibs,
  zig,
}:
stdenv.mkDerivation {
  pname = "notify_cancel";
  version = "0-unstable";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
    zig.hook
  ];
  buildInputs = [ systemdLibs ];

  meta.mainProgram = "notify_cancel";
}
