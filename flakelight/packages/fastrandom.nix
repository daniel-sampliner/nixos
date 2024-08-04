# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  writers,

  coreutils,
  openssl,
  unixtools,
}:
writers.writeExecline { } "/bin/fastrandom" ''
  pipeline -d { ${lib.getExe unixtools.xxd} -l 128 -p /dev/urandom }
  pipeline -d { ${lib.getExe' coreutils "tr"} -d "[:space:]" }
  redirfd -w 2 /dev/null
  ${lib.getExe openssl} enc -aes-256-ctr -pass stdin -nosalt -in /dev/zero
''
