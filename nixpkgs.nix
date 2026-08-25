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

              pkgsDgx = prev.callPackage inputs.dgx { };
              pkgsExtra = mkPkgSet prev;
            }
          )
        ];
      };

      packages =
        let
          filterDerivations = lib.attrsets.filterAttrs (_: lib.attrsets.isDerivation);
          pkgsDgx =
            let
              linkFarm = lib.trivial.pipe pkgs.pkgsDgx [
                filterDerivations

                (lib.attrsets.mapAttrsToList (
                  _: drv: {
                    name = drv.pname;
                    path = drv;
                  }
                ))

                (pkgs.linkFarm "pkgsDgx")
              ];
            in
            linkFarm // linkFarm.passthru.entries;
        in
        filterDerivations (mkPkgSet pkgs) // { inherit pkgsDgx; };
    };
}
