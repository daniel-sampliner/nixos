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
  pname = "vim-apathy";
  src = fetchFromGitHub {
    owner = "tpope";
    repo = pname;
    rev = "27128a0f55189724c841843ba41cd33cf7186032";

    hash = "sha256-E5ZboCQmp7FDAILPoAaGULepyAR90vfrOtaQ3EfdzJg=";
  };
in
vimUtils.buildVimPlugin {
  inherit pname src;
  version = "0-unstable-2021-11-22";

  meta.license = lib.licenses.vim;
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
