# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  devshell,
  inputs',
  lib,
  outputs',
  src,

  nix-eval-jobs,
  nix-fast-build,
  nix-output-monitor,
  nix-update,
}:
devshell.mkShell {
  imports = lib.collectDir { } ./devshellModules;

  devshell =
    let
      git-hooks-check = outputs'.checks.git-hooks;
    in
    {
      motd = "";
      name = (import (src + "/flake.nix")).description;
      packagesFrom = [ outputs'.formatter.passthru.moduleArgs.config.build.devShell ];

      startup.gitconfig.text = ''
        git config --local blame.ignoreRevsFile .git-blame-ignore-revs
        git config --local diff.sopsdiffer.textconv "sops -d"
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
