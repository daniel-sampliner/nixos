# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

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
        license ? lib.licenses.agpl3Plus,
      }:
      nameOrPath: content:
      (writers.makeScriptWriter {
        interpreter = lib.getExe' execline "execlineb" + lib.optionalString (flags != "") (" " + flags);
      } nameOrPath content).overrideAttrs
        { meta.license = license; };
  };
in
runCommandLocal "writers" { } "touch $out" // writers // myWriters
