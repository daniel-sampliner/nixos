# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/profiles/zsh")
  ];

  home.stateVersion = "25.05";
}
