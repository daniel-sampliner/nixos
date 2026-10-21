# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  inputs,
  lib,
  self,
  ...
}:
{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      packages.containers =
        let
          pkgsSlim = pkgs.appendOverlays [
            (_: _: {
              fp = config.allModuleArgs // {
                inherit self;
              };
            })

            (
              final: prev:
              let
                inherit (inputs) nixpkgs_cacert nixpkgs_release;
              in
              {
                caddy = final.callPackage "${nixpkgs_release}/pkgs/by-name/ca/caddy/package.nix" { };
                go_1_26 = final.callPackage "${nixpkgs_cacert}/pkgs/development/compilers/go/1.26.nix" { };
                go_1_27 = final.callPackage "${nixpkgs_release}/pkgs/development/compilers/go/1.27.nix" { };
              }
            )

            (import ./overlays/slim.nix)
            (import ./overlays/containers.nix)
          ];

          ctrSet = lib.filesystem.packagesFromDirectoryRecursive {
            inherit (pkgsSlim) callPackage;
            directory = ./ctrs;
          };

          ctrSet' =
            let
              replacements = [
                {
                  oldDependency = pkgsSlim.cacert;
                  newDependency = inputs'.nixpkgs_cacert.legacyPackages.cacert.overrideAttrs {
                    __intentionallyOverridingVersion = true;
                    version = "3.131";
                  };
                }
              ];
            in
            builtins.mapAttrs (
              _: drv:
              pkgsSlim.replaceDependencies { inherit drv replacements; }
              // {
                passthru = builtins.mapAttrs (
                  _: d:
                  if lib.attrsets.isDerivation d then
                    pkgsSlim.replaceDependencies {
                      drv = d;
                      inherit replacements;
                    }
                  else
                    d
                ) drv.passthru;
              }
            ) ctrSet;
        in
        (pkgsSlim.linkFarm "containers" (
          lib.attrsets.mapAttrsToList (name: path: { inherit name path; }) ctrSet'
        ))
        // {
          passthru = { inherit ctrSet ctrSet'; };
        };
    };
}
