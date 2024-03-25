# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

pkgs:
let
  devshell = import pkgs.inputs.devshell.outPath { nixpkgs = pkgs; };
  pre-commit-check = pkgs.outputs'.checks.pre-commit;
in
devshell.mkShell {
  devshell = {
    motd = "";
    name = "nixos configs";
    startup.pre-commit.text = pre-commit-check.shellHook;

    packages = pre-commit-check.enabledPackages;
  };
}
