# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  inputs,
  withSystem,
  ...
}:
{
  imports = [ inputs.home-manager.flakeModules.default ];

  flake.homeConfigurations =
    let
      homeFileset = lib.fileset.difference (lib.fileset.fileFilter (
        { name, type, ... }: name == "home.nix" && type == "regular"
      ) ./.) (lib.fileset.maybeMissing ./home.nix);

      mkHomeConfiguration =
        path:
        let
          dir = builtins.dirOf path;
          username = builtins.baseNameOf dir |> builtins.split "@" |> builtins.head;
        in
        withSystem (import (dir + "/system.nix")) (
          { pkgs, ... }:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              (_: {
                home.username = username;
                home.homeDirectory = "/home/${username}";
              })

              ../homeModules

              path
            ];

            extraSpecialArgs.myModulesPath = ../homeModules;
          }
        );

      homes =
        lib.fileset.toList homeFileset
        |> builtins.map (
          path: lib.attrsets.nameValuePair (dirOf path |> baseNameOf) (mkHomeConfiguration path)
        )
        |> builtins.listToAttrs;
    in
    homes;
}
