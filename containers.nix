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
      pkgs,
      ...
    }:
    {
      packages.containers =
        let
          pkgsSlim = pkgs.appendOverlays [
            (_: _: {
              fp = config.allModuleArgs // {
                inherit inputs self;
              };
            })

            (import ./overlays/slim.nix)
            (import ./overlays/containers.nix)
          ];

          ctrSet = lib.filesystem.packagesFromDirectoryRecursive {
            inherit (pkgsSlim) callPackage;
            directory = ./ctrs;
          };
        in
        pkgsSlim.linkFarm "containers" (
          lib.attrsets.mapAttrsToList (name: path: { inherit name path; }) ctrSet
        );
    };
}
