# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitHub,
  lib,
  nix-update-script,
  vimUtils,
}:
let
  pname = "vim-characterize";
  src = fetchFromGitHub {
    owner = "tpope";
    repo = pname;
    rev = "a8bffac6cead6b2869d939ecad06312b187a4c79";

    hash = "sha256-H+lao2LLWu+f11xOF5aH5D4a8GY6ozmgZ/uLzgGWAGw=";
  };
in
vimUtils.buildVimPlugin {
  inherit pname src;
  version = "1.1-unstable-2024-11-14";

  meta.license = lib.licenses.vim;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
