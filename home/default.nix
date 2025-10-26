# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  inputs,
  lib,
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
          username = lib.trivial.pipe dir [
            builtins.baseNameOf
            (builtins.split "@")
            builtins.head
          ];
        in
        withSystem (import (dir + "/system.nix")) (
          { pkgs, ... }:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              (inputs.dgx + "/homeModules")
              ../homeModules

              (_: {
                home.packages =
                  let
                    input-paths = pkgs.writeTextFile {
                      name = "input-paths";
                      text = lib.trivial.pipe inputs [
                        (lib.attrsets.mapAttrsToList (_: v: v.outPath))
                        (builtins.concatStringsSep "\n")
                        (s: s + "\n")
                      ];
                      destination = "/share/home-manager/inputs.txt";
                    };
                  in
                  [ input-paths ];

                home.username = username;
                home.homeDirectory = "/home/${username}";

                nix =
                  let
                    copyInputs = [
                      "nixpkgs"
                      "unstable"
                    ];

                    mkNixPath = input: "${input}=${inputs.${input}.outPath}";

                    mkRegistry =
                      input:
                      lib.attrsets.nameValuePair input {
                        exact = true;

                        from = {
                          id = input;
                          type = "indirect";
                        };

                        to = {
                          type = "path";
                          path = inputs.${input}.outPath;
                        };
                      };
                  in
                  {
                    nixPath = builtins.map mkNixPath copyInputs;
                    registry = lib.trivial.pipe copyInputs [
                      (builtins.map mkRegistry)
                      builtins.listToAttrs
                    ];
                  };

                programs.command-not-found.dbPath = "${inputs.nixpkgs}/programs.sqlite";
              })

              path
            ];

            extraSpecialArgs.dgxModulesPath = "${inputs.dgx}/homeModules";
            extraSpecialArgs.myModulesPath = ../homeModules;
          }
        );

      homes = lib.trivial.pipe homeFileset [
        lib.fileset.toList
        (builtins.map (
          path: lib.attrsets.nameValuePair (baseNameOf (dirOf path)) (mkHomeConfiguration path)
        ))
        builtins.listToAttrs
      ];
    in
    homes;
}
