# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

_: {
  imports = [
    ../profiles
    ../profiles/bat.nix
    ../profiles/nvim
    ../profiles/zsh
  ];

  home.stateVersion = "22.05";
}
