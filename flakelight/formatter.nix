# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

pkgs:
pkgs.inputs.treefmt-nix.lib.mkWrapper pkgs {
  projectRootFile = "flake.nix";

  programs = {
    nixfmt-rfc-style.enable = true;
    nixfmt-rfc-style.package = pkgs.inputs'.unstable.legacyPackages.nixfmt-rfc-style;

    shfmt.enable = true;
    shfmt.indent_size = null;

    taplo.enable = true;
  };

  settings.formatter.nixfmt-rfc-style.excludes = [ "hardware-configuration.nix" ];
}
