# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      devShells.default =
        let
          mkShellMinimal =
            {
              name,
              packages ? [ ],
              inputsFrom ? [ ],
            }:
            let
              allPackages =
                lib.attrsets.catAttrs "nativeBuildInputs" inputsFrom
                |> lib.lists.flatten
                |> lib.subtractLists inputsFrom
                |> (p: packages ++ p);

            in
            builtins.derivation {
              inherit name system;

              builder = lib.meta.getExe pkgs.bash;
              outputs = [ "out" ];

              XDG_DATA_DIRS =
                builtins.map (p: p + "/share") allPackages
                |> builtins.filter lib.filesystem.pathIsDirectory
                |> builtins.concatStringsSep ":";

              stdenv = pkgs.writeTextDir "setup" ''
                PATH="${lib.strings.makeBinPath allPackages}"
                export PATH

                export XDG_DATA_DIRS
              '';

              args = [
                (pkgs.writeText "builder.sh" (pkgs.mkShellNoCC { }).buildPhase)
              ];
            };
        in
        mkShellMinimal {
          name = (import ./flake.nix).description;
          inputsFrom = [ config.treefmt.build.devShell ];

          packages = builtins.attrValues {
            inherit (pkgs)
              home-manager
              nix-output-monitor
              ;

            inherit (pkgs.pkgsUnstable)
              reuse
              ;
          };
        };
    };
}
