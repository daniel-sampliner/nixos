# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
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

  programs.ssh.package = lib.mkForce null;

  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 550 ''
      fpath+=(/usr/share/zsh/site-functions /usr/share/zsh/vendor-functions)
    '')

    (lib.mkOrder 0 ''
      if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '')
  ];
}
