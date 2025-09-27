# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  mkPkgSet =
    pkgs:
    lib.filesystem.packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage newScope;
      directory = ./pkgs;
    };
in
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      mkPkgSet =
        pkgs:
        lib.filesystem.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage newScope;
          directory = ./pkgs;
        };
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            pkgsUnstable = import inputs.unstable {
              inherit system;
              overlays = [
                (final: prev: { pkgsExtra = mkPkgSet prev; })
              ];
            };

            pkgsExtra = mkPkgSet prev;
          })
        ];
      };

      packages = mkPkgSet pkgs |> lib.attrsets.filterAttrs (_: lib.attrsets.isDerivation);
    };
}
