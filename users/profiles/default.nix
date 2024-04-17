# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ flake, pkgs, ... }:
{
  imports = [
    ./aliases
    ./bat.nix
    ./direnv
    ./git.nix
    ./kitty.nix
    ./parallel.nix
  ];

  home.packages = builtins.attrValues {
    inherit (flake.inputs'.unstable.legacyPackages) nixfmt-rfc-style;

    inherit (pkgs)
      age
      coreutils-full
      dash
      execline
      eza
      fastrandom
      fd
      file
      fzf
      gh
      hyperfine
      less
      man-pages
      man-pages-posix
      pv
      ripgrep
      rsync
      shellcheck
      shfmt
      sops
      ;
  };

  programs.home-manager.enable = true;

  programs.zsh.envExtra = ''
    typeset -aUT XDG_CONFIG_DIRS xdg_config_dirs
    typeset -aUT XDG_DATA_DIRS xdg_data_dirs
  '';

  xdg.enable = true;
}
