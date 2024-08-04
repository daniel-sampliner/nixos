# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  patchelf,
  stdenv,
  system,
  writers,
}:
let
  inherit ((lib.systems.parse.mkSystemFromString system).cpu) arch;
in
writers.writeExecline { flags = "-WS0"; } "/bin/patchelf-auto-interp" ''
  ${lib.getExe' patchelf "patchelf"}
    --set-interpreter "${stdenv.cc.libc}/lib/ld-linux-${arch}.so.2"
    $@
''
