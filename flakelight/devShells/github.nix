# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

pkgs:
let
  devshell = import pkgs.inputs.devshell.outPath { nixpkgs = pkgs; };
in
devshell.mkShell {
  devshell = {
    motd = "";

    packages = builtins.attrValues {
      inherit (pkgs.inputs'.nix2container.packages) nix2container-bin skopeo-nix2container;
    };
  };
}