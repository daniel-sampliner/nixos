# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      system,
      ...
    }:
    let
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
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          (
            final: prev:
            let
              pkgsUnstable = import inputs.unstable {
                inherit system;
                overlays = [
                  (final: prev: { pkgsExtra = mkPkgSet prev; })
                ];
              };
            in
            {
              inherit pkgsUnstable;

              pnpm_10_29_2 = prev.pnpm_10;
              pkgsExtra = mkPkgSet prev;
            }
          )
        ];
      };

      packages = lib.attrsets.filterAttrs (_: lib.attrsets.isDerivation) (mkPkgSet pkgs);
    };
}
