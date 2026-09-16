# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
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
        "fzf.nix"
        "go"
        "javascript.nix"
        "jujutsu"
        "k8s.nix"
        "kitty.nix"
        "notify-cancel.nix"
        "rnnoise.nix"
        "starlark.nix"
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
      ./pi-coding-agent.nix
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
      par
      prek
      spacer
      units
      wl-clipboard
      ;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    PARINIT = "rTbgqR B=.,?'_A_a_@ Q=_s>|";
    TMPDIR = "\${XDG_RUNTIME_DIR:-/tmp}";
  };

  programs.bash.enable = true;
  programs.command-not-found.enable = true;
  programs.poetry.enable = true;
  programs.starship.settings.shell.zsh_indicator = "";
  programs.uv.enable = true;

  home.stateVersion = "26.05";
}
