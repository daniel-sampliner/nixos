# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  dgxModulesPath,
  lib,
  myModulesPath,
  pkgs,
  ...
}:
{
  imports =
    let
      profiles = [
        "foreign.nix"
        "fzf.nix"
        "jujutsu"
        "kitty.nix"
        "notify-cancel.nix"
        "rnnoise.nix"
        "starship"
        "watchman.nix"
        "zsh"
      ];
    in
    builtins.map (p: myModulesPath + "/profiles/${p}") profiles
    ++ [
      (dgxModulesPath + "/profiles")

      ./brave.nix
      ./clush.nix
      ./gpgkey.nix
      ./hide-fleet-icon
      ./mpv
      ./ssh.nix
    ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      bat
      btop-cuda
      delta
      glow
      prek
      spacer
      ;
  };

  programs.bash.enable = true;
  programs.command-not-found.enable = true;
  programs.starship.settings.shell.zsh_indicator = "";
  programs.uv.enable = true;

  home.stateVersion = "25.05";
}
