# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ mise, runCommand }:
let
  pname = "mise-inits";
  inherit (mise) version;
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";
    buildInputs = [ mise ];
  }
  ''
    export MISE_CACHE_DIR=''${TEMPDIR:?}/cache
    mkdir -p "$out/share/mise/shell_init"
    for sh in bash fish zsh; do
      mise activate "$sh" >"$out/share/mise/shell_init/mise.$sh"
    done
  ''
