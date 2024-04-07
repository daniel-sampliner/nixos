# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  execline,
  lib,
  runCommandLocal,
  writers,
}:
let
  myWriters = {
    writeExecline =
      {
        flags ? "-WP",
      }:
      writers.makeScriptWriter {
        interpreter = lib.getExe' execline "execlineb" + lib.optionalString (flags != "") (" " + flags);
      };
  };
in
runCommandLocal "writers" { } "touch $out" // writers // myWriters
