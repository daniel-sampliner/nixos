# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ runCommand, starship }:
let
  pname = "starship-inits";
  inherit (starship) version;
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";
    buildInputs = [ starship ];
  }
  ''
    export STARSHIP_CACHE=''${TEMPDIR:?}/cache
    mkdir -p -- "$out/share/starship/shell_init"
    for sh in bash fish zsh tcsh; do
      starship init --print-full-init "$sh" >"$out/share/starship/shell_init/starship.$sh"
    done
  ''
