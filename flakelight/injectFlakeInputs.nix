# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ src }:
{ inputs, lib, ... }:
{
  nix = {
    channel.enable = false;
    nixPath = lib.mapAttrsToList (n: v: "${n}=${v}") inputs;

    registry =
      let
        urlRefs =
          let
            srcInputs = (import "${src}/flake.nix").inputs;
          in
          builtins.mapAttrs (name: input: {
            from = {
              id = name;
              type = "indirect";
            };
            to =
              let
                srcFlakeRef = builtins.parseFlakeRef srcInputs.${name}.url;
              in
              {
                inherit (srcFlakeRef) owner repo type;
                inherit (input) rev;
              };
          }) inputs;

        localRefs = lib.mapAttrs' (
          n: v:
          lib.nameValuePair "${n}-local" {
            flake = v;
            from = {
              id = n;
              ref = "local";
              type = "indirect";
            };
          }
        ) inputs;
      in
      urlRefs // localRefs;
  };

  system.extraDependencies = lib.pipe inputs [
    builtins.attrValues
    (builtins.map (i: i.outPath))
  ];
}
