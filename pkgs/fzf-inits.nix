# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ fzf, runCommand }:
let
  pname = "fzf-inits";
  inherit (fzf) version;
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";
    buildInputs = [ fzf ];
  }
  ''
    mkdir -p "$out/share/fzf/shell_init"
    for sh in bash fish zsh; do
      fzf --"$sh" >"$out/share/fzf/shell_init/fzf.$sh"
    done
  ''
