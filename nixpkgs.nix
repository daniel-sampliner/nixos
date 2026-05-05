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

              inherit (pkgsUnstable)
                vimPlugins
                ;

              pkgsExtra = mkPkgSet prev;
            }
          )

          (
            final: prev:
            assert (
              lib.assertMsg (
                !lib.trivial.functionArgs inputs.nixpkgs.legacyPackages.${system}.zig.fetchDeps ? fetchAll
              ) "No longer necessary to override zig.fetchDeps"
            );
            let
              dir = lib.trivial.pipe inputs'.unstable.legacyPackages.zig.meta.position [
                (builtins.split ":")
                builtins.head
                builtins.dirOf
              ];

              fetchDeps = inputs'.nixpkgs.legacyPackages.callPackage (dir + "/fetcher.nix") { };

              zigPackages = builtins.mapAttrs (
                _: v: if lib.attrsets.isDerivation v then v // { inherit fetchDeps; } else v
              ) prev.zigPackages;

              zigs = lib.trivial.pipe zigPackages [
                (lib.attrsets.filterAttrs (_: v: lib.attrsets.isDerivation v))
                (lib.attrsets.mapAttrs' (n: v: lib.attrsets.nameValuePair ("zig_${n}") (v)))
              ];
            in
            {
              inherit (zigPackages) ;

              zig = prev.zig // {
                inherit fetchDeps;
              };
            }
          )
        ];
      };

      packages = lib.attrsets.filterAttrs (_: lib.attrsets.isDerivation) (mkPkgSet pkgs);
    };
}
