# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
{
  home.sessionSearchVariables = {
    TERMINFO_DIRS = lib.mkMerge [
      (lib.mkBefore [ "/usr/lib64/kitty/terminfo" ])
      (lib.mkAfter [ "/usr/share/terminfo" ])
    ];

    XDG_DATA_DIRS = [
      "$HOME/.local/share/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
      "$HOME/.nix-profile/share"
      "/nix/var/nix/profiles/default/share"
      "/usr/local/share"
      "/usr/share"
    ];
  };

  programs = {
    kitty.package = lib.mkForce pkgs.emptyDirectory;
    ssh.package = lib.mkForce null;

    zsh.initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        fpath=(
          ''${KITTY_INSTALLATION_DIR:+"$KITTY_INSTALLATION_DIR"/shell-integration/zsh/completions}
          $fpath
        )

        () {
          emulate -L zsh
          setopt rcexpandparam
          local dirs=(site-functions vendor-functions vendor-completions)
          fpath+=( "/usr/share/zsh/''${dirs[@]}" )
        }
      '')

      (lib.mkOrder 0 ''
        if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi
      '')
    ];
  };
}
