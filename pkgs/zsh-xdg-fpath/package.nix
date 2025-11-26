# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  installShellFiles,
  runCommand,
  zsh,
}:
let
  pname = "zsh-xdg-fpath";
  version = "0-unstable";
in
runCommand pname
  {
    nativeBuildInputs = [
      installShellFiles
      zsh
    ];
    inherit pname version;
    name = "${pname}-${version}";
  }
  ''
    installShellCompletion "${./_xdg_fpath_init.zsh}"
    zsh -c "zcompile -Uz \"$out/share/zsh/site-functions/_xdg_fpath_init\""
  ''
