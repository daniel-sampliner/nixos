# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  runCommand,
  zsh,
  zsh-completions,
}:
let
  pname = "zsh-completions-compiled";
  inherit (zsh-completions) version;
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";

    nativeBuildInputs = [ zsh ];
  }
  ''
    dir=$out/share/zsh/site-functions
    install -Dm0644 -t "$dir" "${zsh-completions}/share/zsh/site-functions"/*
    zsh -s "$dir" <<-'EOF'
    for f in "$1"/*(.N); do
      zcompile -U "$f"
    done
    EOF
  ''
