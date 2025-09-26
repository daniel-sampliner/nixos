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
                    nixPath = copyInputs |> builtins.map mkNixPath;
                    registry = copyInputs |> builtins.map mkRegistry |> builtins.listToAttrs;
                  };

                programs.command-not-found.dbPath = "${inputs.nixpkgs}/programs.sqlite";
              })

              ../homeModules

              path
            ];

            extraSpecialArgs.dgxModulesPath = "${inputs.dgx}/homeModules";
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
