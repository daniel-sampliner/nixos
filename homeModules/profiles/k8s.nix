# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }: {
  home.packages = builtins.attrValues {
    inherit (pkgs)
      dyff
      kube-capacity
      kubectl
      kubectl-neat
      kubectl-view-allocations
      kubespy
      stern
      ;

    inherit (pkgs.pkgsExtra)
      kubectl-completions
      kubeswitch-inits
      ;
  };

  programs.kubeswitch = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = false;
  };

  programs.zsh.initContent = ''
    autoload -RUk kswitch
  '';
}
