# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ installShellFiles, runCommand }:
let
  pname = "zsh-xdg-fpath";
  version = "0-unstable";
in
runCommand pname
  {
    nativeBuildInputs = [ installShellFiles ];
    inherit pname version;
    name = "${pname}-${version}";
  }
  ''
    installShellCompletion "${./_xdg_fpath_init.zsh}"
  ''
