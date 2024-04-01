# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  inputs,
  lib,
  outputs,
  src,
  ...
}:
let
  hostsDir = "${src}/hosts";

  hostSystems = {
    default = "x86_64-linux";
  };

  extraModules = {
    "thiccpad" = [ inputs.nixos-hardware.nixosModules.lenovo-legion-16ach6h-nvidia ];
  };

  hosts = lib.pipe hostsDir [
    builtins.readDir
    (lib.filterAttrs (n: t: n != "profiles" && t == "directory"))
    (builtins.mapAttrs (d: _: "${hostsDir}/${d}/configuration.nix"))
    (lib.filterAttrs (_: f: builtins.pathExists f))
  ];

  mkNixosSystem = host: {
    system = hostSystems.${host} or hostSystems.default;

    modules =
      builtins.attrValues outputs.nixosModules or { }
      ++ extraModules.${host} or [ ]
      ++ [
        (import ./injectFlakeInputs.nix { inherit src; })
        (_: {
          nixpkgs.config = config.nixpkgs.config;
          networking.hostName = builtins.baseNameOf host;
        })

        "${hostsDir}/${host}/configuration.nix"
      ];
  };
in
builtins.mapAttrs (h: _: mkNixosSystem h) hosts
