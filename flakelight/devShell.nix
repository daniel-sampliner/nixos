# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

pkgs:
let
  inherit (pkgs) flakelight;

  devshell = import pkgs.inputs.devshell.outPath { nixpkgs = pkgs; };
  git-hooks-check = pkgs.outputs'.checks.git-hooks;
in
devshell.mkShell {
  imports = builtins.attrValues (flakelight.importDir ./devshellModules);

  devshell = {
    motd = "";
    name = "nixos configs";

    startup.sopsdiffer.text = ''
      git config diff.sopsdiffer.textconv "sops -d"
    '';

    startup.git-hooks.text = git-hooks-check.shellHook;

    packages =
      builtins.attrValues {
        inherit (pkgs)
          nix-eval-jobs
          nix-fast-build
          nix-output-monitor
          nix-update
          pre-commit
          ;

        inherit (pkgs.inputs'.nix2container.packages) skopeo-nix2container;
      }
      ++ git-hooks-check.enabledPackages;
  };
}
