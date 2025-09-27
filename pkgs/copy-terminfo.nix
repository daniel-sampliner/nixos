# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  runCommand,

  execline,
}:
let
  pname = "copy-terminfo";
  version = "0-unstable";

  script = execline.passthru.writeScript "${pname}-script" "-Ws1" ''
    multisubstitute {
      importas -D "" VERBOSE_ARG VERBOSE_ARG
      importas -i TERM TERM
    }

    backtick -E terminfo { mktemp --tmpdir "copy-terminfo.''${TERM}.XXXXX" }
    if { eltest -n $terminfo }

    foreground {
      if { redirfd -w 1 $terminfo infocmp -a $TERM }
      ifelse {
        redirfd -r 0 $terminfo
        ssh $@ $1 tic ''${VERBOSE_ARG} -x -o ''${HOME:?}/.terminfo -
      } { }

      backtick -E location {
        pipeline { grep -E "^#[[:blank:]]+Reconstructed" $terminfo }
        grep -Eo "\\bterminfo/.*"
      }
      ifelse -n
        { eltest -n $location }
        {
          foreground {
            fdmove -c 1 2
            echo could not find terminfo for TERM: $TERM
          }
          exit 1
        }

      redirfd -r 0 $terminfo
      ssh $@ $1 install ''${VERBOSE_ARG} -Dm0644 /dev/stdin ''${HOME:?}/.''${location}
    }

    importas -i ret ?
    foreground { rm ''${VERBOSE_ARG} -f -- $terminfo }
    exit $ret
  '';
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";

    meta = {
      license = lib.licenses.agpl3Plus;
      mainProgram = pname;
    };
  }
  ''
    install -D -- "${script}" "$out/bin/copy-terminfo"
  ''
