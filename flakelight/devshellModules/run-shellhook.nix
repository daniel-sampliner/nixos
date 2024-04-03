# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.commands = [
    {
      name = "run-shellhook";
      help = "run devShell shellHook";

      command = ''
        #!${lib.getExe pkgs.bash}
        export PS4='+(''${BASH_SOURCE##*/}:''${LINENO}): ''${FUNCNAME[0]:+''${FUNCNAME[0]}(): }'
        if (( DEBUG > 0 )); then
          set -x
        fi

        . "''${DEVSHELL_DIR:?}"/env.bash
      '';
    }
  ];
}
