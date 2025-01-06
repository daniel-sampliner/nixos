# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  writers,

  execline,
}:
{
  writeExecline =
    {
      flags ? "-WP",
      runtimeInputs ? [ ],
    }:
    nameOrPath: content:
    writers.makeScriptWriter {
      interpreter = lib.getExe' execline "execlineb" + lib.optionalString (flags != "") (" " + flags);
      makeWrapperArgs = lib.lists.optionals (runtimeInputs != [ ]) [
        "--prefix"
        "PATH"
        ":"
        (lib.strings.makeBinPath runtimeInputs)
      ];
    } nameOrPath content;
}
