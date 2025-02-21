# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  devshell,
  inputs',
  lib,
  moduleArgs,

  nix-eval-jobs,
  nix-fast-build,
  nix-output-monitor,
  nix-update,
  stdenvNoCC,
  systemd-sops,
  ...
}:
devshell.mkShell {
  imports = lib.collectDir { } ./devshellModules;

  devshell =
    let
      pkgs = moduleArgs.pkgsFor.${stdenvNoCC.hostPlatform.system};
      checks = builtins.mapAttrs (_: c: c pkgs) (moduleArgs.config.checks pkgs);
    in
    {
      motd = "";
      name = moduleArgs.config.description;
      packagesFrom = [
        (moduleArgs.config.formatter pkgs).passthru.moduleArgs.config.build.devShell
        systemd-sops
      ];

      startup.gitconfig.text = ''
        git config --local blame.ignoreRevsFile .git-blame-ignore-revs
        git config --local diff.sopsdiffer.textconv "sops -d"
      '';

      startup.git-hooks.text = checks.git-hooks.shellHook;

      packages = [
        nix-eval-jobs
        nix-fast-build
        nix-output-monitor
        nix-update

        inputs'.nix2container.packages.skopeo-nix2container
      ] ++ checks.git-hooks.enabledPackages;
    };
}
