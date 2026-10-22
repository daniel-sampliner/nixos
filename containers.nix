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
          cacert = inputs'.nixpkgs_cacert.legacyPackages.cacert.overrideAttrs {
            __intentionallyOverridingVersion = true;
            version = "3.131";
          };

          pkgsSlim = pkgs.appendOverlays [
            (_: _: {
              fp = config.allModuleArgs // {
                inherit inputs self;
              };
            })

            (
              final: prev:
              let
                inherit (inputs) nixpkgs_cacert;
                inherit (lib.asserts) assertMsg;
                inherit (lib.strings) versionOlder;
              in
              assert assertMsg (versionOlder pkgs.cacert.version "3.131.1") "cacert overlay unnecessary";
              assert assertMsg (versionOlder pkgs.go_1_26.version "1.26.10") "go_1_26 overlay unnecessary";
              {
                dockerTools = prev.dockerTools // {
                  caCertificates = prev.dockerTools.caCertificates.overrideAttrs (prev': {
                    buildCommand = lib.strings.replaceString "${prev.cacert}" "${cacert}" prev'.buildCommand;
                  });
                };

                go_1_26 = final.callPackage "${nixpkgs_cacert}/pkgs/development/compilers/go/1.26.nix" { };
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
                  newDependency = cacert;
                }
              ];
            in
            builtins.mapAttrs (
              _: drv:
              lib.recursiveUpdate (pkgsSlim.replaceDependencies { inherit drv replacements; }) {
                meta = { inherit (drv.meta) repository tag tags; };

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
