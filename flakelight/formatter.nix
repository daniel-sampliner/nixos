# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

pkgs:
pkgs.inputs.treefmt-nix.lib.mkWrapper pkgs {
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;

    shfmt.enable = true;
    shfmt.indent_size = null;

    taplo.enable = true;
  };

  settings.formatter.nixfmt.excludes = [ "hardware-configuration.nix" ];
}
