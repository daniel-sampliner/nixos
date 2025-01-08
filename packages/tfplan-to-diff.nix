# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  writers,

  gnused,
}:
writers.writeExecline
  {
    flags = "-WS0";
  }
  "/bin/tfplan-to-diff"
  ''
    ${lib.getExe gnused} -E
      -e "s/^([[:blank:]]*)([-+~])/\\2\\1/"
      -e "s/^~/!/"
      $@
  ''
