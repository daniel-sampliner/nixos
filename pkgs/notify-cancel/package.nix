# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  pkg-config,
  stdenv,
  systemdLibs,
  zig_0_15,
}:
stdenv.mkDerivation {
  pname = "notify_cancel";
  version = "0-unstable";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
    zig_0_15.hook
  ];
  buildInputs = [ systemdLibs ];

  meta.mainProgram = "notify_cancel";
}
