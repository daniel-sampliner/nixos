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
        "javascript.nix"
        "jujutsu"
        "k8s.nix"
        "kitty.nix"
        "notify-cancel.nix"
        "rnnoise.nix"
        "starship"
        "watchman.nix"
        "zig"
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
      ./vault.nix
    ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      bat
      btop-cuda
      delta
      glab
      glow
      prek
      spacer
      wl-clipboard
      ;

    inherit (pkgs.pkgsDgx) kubectl-nkx;
  };

  programs.bash.enable = true;
  programs.command-not-found.enable = true;
  programs.poetry.enable = true;
  programs.starship.settings.shell.zsh_indicator = "";
  programs.uv.enable = true;

  home.stateVersion = "26.05";
}
