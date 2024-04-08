# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

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
