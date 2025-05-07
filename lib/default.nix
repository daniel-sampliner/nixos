# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, self }:
let
  collect = import ./collect.nix { inherit lib; };

  infuse = import ./infuse.nix {
    inherit lib;
    inherit (self.inputs) infuse;
  };

  mkNixpkgs =
    pkgs: system:
    {
      overlays ? [ ],
      config ? nixpkgs.config,
    }:
    import pkgs {
      inherit config overlays system;
    };

  mkScope =
    pkgs: directory:
    lib.customisation.makeScope pkgs.newScope (
      final:
      let
        inherit (lib.filesystem) packagesFromDirectoryRecursive;
        inherit directory;

        packageNames =
          lib.pipe
            {
              callPackage = path: args: path;
              inherit directory;
            }
            [
              packagesFromDirectoryRecursive
              (lib.attrsets.filterAttrs (_: builtins.isPath))
              builtins.attrNames
            ];

        packages = packagesFromDirectoryRecursive {
          inherit (final) callPackage;
          inherit directory;
        };
      in
      packages
      // {
        lib = pkgs.lib.extend (_: _: self.lib);

        self =
          let
            cond = (as: !(builtins.hasAttr pkgs.system as));
            func = (_: v: if builtins.isAttrs v then builtins.getAttr pkgs.system v else v);
          in
          lib.attrsets.mapAttrsRecursiveCond cond func self;

        passthru.packages = lib.attrsets.getAttrs packageNames packages;
      }
    );

  nixpkgs.config = {
    allowUnfreePredicate =
      let
        unfreePkgs = [
          "nvidia-settings"
          "nvidia-x11"
        ];
      in
      pkg: builtins.elem (lib.strings.getName pkg) unfreePkgs;
  };
in
{
  inherit
    mkNixpkgs
    mkScope
    nixpkgs
    ;

  inherit (collect) collectDir collectDirAttrs;
  inherit (infuse.v1) infuse;

  flake = self;
}
