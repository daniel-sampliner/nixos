# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  dgxModulesPath,
  myModulesPath,
  pkgs,
  ...
}:
{
  imports =
    let
      profiles = [
        "foreign.nix"
        "jujutsu"
        "kitty.nix"
        "rnnoise.nix"
        "starship"
        "zsh"
      ];
    in
    builtins.map (p: myModulesPath + "/profiles/${p}") profiles
    ++ [
      (dgxModulesPath + "/profiles")

      ./gpgkey.nix
      ./hide-fleet-icon
      ./ssh.nix
    ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      bat
      delta
      glow
      spacer
      ;
  };

  programs.bash.enable = true;
  programs.command-not-found.enable = true;
  programs.starship.settings.shell.zsh_indicator = "";

  home.stateVersion = "25.05";
}
