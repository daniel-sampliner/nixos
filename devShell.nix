# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  devshell,
  flakelight,
  inputs',
  outputs',
  src,

  nix-eval-jobs,
  nix-fast-build,
  nix-output-monitor,
  nix-update,
}:
devshell.mkShell {
  imports = builtins.attrValues (flakelight.importDir ./devshellModules);

  devshell =
    let
      git-hooks-check = outputs'.checks.git-hooks;
    in
    {
      motd = "";
      name = (import (src + "/flake.nix")).description;
      packagesFrom = [ outputs'.formatter.passthru.moduleArgs.config.build.devShell ];

      startup.sopsdiffer.text = ''
        git config diff.sopsdiffer.textconv "sops -d"
      '';

      startup.git-hooks.text = git-hooks-check.shellHook;

      packages = [
        nix-eval-jobs
        nix-fast-build
        nix-output-monitor
        nix-update

        inputs'.nix2container.packages.skopeo-nix2container
      ] ++ git-hooks-check.enabledPackages;
    };
}
