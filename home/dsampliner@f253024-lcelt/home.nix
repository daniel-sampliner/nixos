# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/profiles/zsh")
    ./kitty.nix
  ];

  home.sessionSearchVariables = {
    XDG_DATA_DIRS = [
      "$HOME/.local/share/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
      "$HOME/.nix-profile/share"
      "/nix/var/nix/profiles/default/share"
      "/usr/local/share"
      "/usr/share"
    ];
  };

  home.stateVersion = "25.05";

  programs.zsh.initContent = lib.mkOrder 0 ''
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';
}
