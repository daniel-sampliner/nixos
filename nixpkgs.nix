# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
  perSystem =
    { inputs', ... }:
    let
      stablePkgs = inputs'.nixpkgs.legacyPackages;
      unstablePkgs = inputs'.unstable.legacyPackages;

      mkPkgSet =
        pkgs:
        (lib.filesystem.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage newScope;
          directory = ./pkgs;
        }).overrideScope
          (
            final: prev: {
              inherit inputs';
            }
          );

      pkgsExtra = mkPkgSet stablePkgs;
    in
    {
      _module.args.pkgs = stablePkgs // {
        pkgsUnstable = unstablePkgs // {
          pkgsExtra = mkPkgSet unstablePkgs;
        };

        inherit pkgsExtra;
      };

      packages = lib.attrsets.filterAttrs (_: lib.attrsets.isDerivation) pkgsExtra;
    };
}
