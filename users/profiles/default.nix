# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

_: {
  imports = [ ./aliases ];

  programs.zsh.envExtra = ''
    typeset -aUT XDG_CONFIG_DIRS xdg_config_dirs
    typeset -aUT XDG_DATA_DIRS xdg_data_dirs
  '';

  xdg.enable = true;
}
