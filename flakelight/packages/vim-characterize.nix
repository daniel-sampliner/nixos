# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitHub,
  lib,
  vimUtils,
}:
let
  pname = "vim-characterize";
  src = fetchFromGitHub {
    owner = "tpope";
    repo = pname;
    rev = "7fc5b75e7a9e46676cf736b56d99dd32004ff3d6";

    hash = "sha256-H+lao2LLWu+f11xOF5aH5D4a8GY6ozmgZ/uLzgGWAGw=";
  };
in
vimUtils.buildVimPlugin {
  inherit pname src;
  version = "unstable-2023-11-10";

  meta.license = lib.licenses.vim;
}
