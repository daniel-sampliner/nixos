# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  execline,
  writers,
}:

let
  writeExecline =
    {
      flags ? "-WP",
      runtimeInputs ? [ ],
    }:
    nameOrPath: content:

    writers.makeScriptWriter {
      interpreter =
        lib.meta.getExe' execline "execlineb" + lib.strings.optionalString (flags != "") (" " + flags);

      makeWrapperArgs = lib.lists.optionals (runtimeInputs != [ ]) [
        "--prefix"
        "PATH"
        ":"
        (lib.strings.makeBinPath runtimeInputs)
      ];
    } nameOrPath content;
in
{
  inherit writeExecline;
  writeExeclineBin =
    args: name: content:
    writeExecline args "/bin/${name}" content;
}
