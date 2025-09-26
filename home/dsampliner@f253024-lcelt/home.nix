# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ dgxModulesPath, myModulesPath, ... }:
{
  imports =
    let
      profiles = [
        "foreign.nix"
        "jujutsu.nix"
        "zsh"
      ];
    in
    builtins.map (p: myModulesPath + "/profiles/${p}") profiles
    ++ [
      (dgxModulesPath + "/profiles")

      ./gpgkey.nix
      ./kitty.nix
      ./ssh.nix
    ];

  programs.command-not-found.enable = true;

  home.stateVersion = "25.05";
}
