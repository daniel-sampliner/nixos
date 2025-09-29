# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  imports = [
    ./aliases
    ./fonts.nix
    ./git.nix
    ./mise
    ./nvim.nix
    ./ssh.nix
  ];

  home = {
    packages = builtins.attrValues {
      inherit (pkgs)
        age
        coreutils-full
        execline
        eza
        fd
        file
        fzf
        hyperfine
        jq
        less
        man-pages
        man-pages-posix
        nix-output-monitor
        nixfmt-rfc-style
        parallel
        pv
        ripgrep
        rsync
        shellcheck
        shfmt
        sops
        ;
    };

    preferXdgDirectories = true;

    sessionVariables = {
      LESS = "-Ri";
      LESSCHARSET = "utf-8";
      PAGER = "less";
      SYSTEMD_LESS = "FRSMi";
    };
  };

  manual.manpages.enable = true;

  nix.gc = {
    automatic = true;
    frequency = "daily";
    options = "--delete-older-than 30d";
    persistent = true;
    randomizedDelaySec = "6hours";
  };

  programs.home-manager.enable = true;
  xdg.enable = true;
}
