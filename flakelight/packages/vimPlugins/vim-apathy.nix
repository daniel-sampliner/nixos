# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ fetchFromGitHub, vimUtils }:
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
  version = "unstable-2021-11-22";
}
