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

  hosts = lib.pipe hostsDir [
    builtins.readDir
    (lib.filterAttrs (n: t: n != "profiles" && t == "directory"))
    (builtins.mapAttrs (d: _: "${hostsDir}/${d}/configuration.nix"))
    (lib.filterAttrs (_: f: builtins.pathExists f))
  ];

  mkNixosSystem = host: {
    system = hostSystems.${host} or hostSystems.default;

    modules = builtins.attrValues outputs.nixosModules or { } ++ [
      (_: {
        nix = {
          channel.enable = false;
          nixPath = lib.mapAttrsToList (n: v: "${n}=${v}") inputs;

          registry =
            let
              mkFlakeRegistry =
                name:
                {
                  owner ? "nixos",
                  repo ? null,
                  type ? "github",
                }:
                {
                  from = {
                    id = name;
                    type = "indirect";
                  };

                  to = {
                    inherit owner type;
                    inherit (inputs.${name}.sourceInfo) rev;

                    repo = if repo != null then repo else name;
                  };
                };
            in
            {
              devshell = mkFlakeRegistry "devshell" { owner = "numtide"; };
              flake-utils = mkFlakeRegistry "flake-utils" { owner = "nix-community"; };
              flakelight = mkFlakeRegistry "flakelight" { repo = "nix-community"; };
              git-hooks = mkFlakeRegistry "git-hooks" { repo = "cachix"; };
              nixpkgs = mkFlakeRegistry "nixpkgs" { };
              treefmt-nix = mkFlakeRegistry "treefmt-nix" { repo = "cachix"; };
              unstable = mkFlakeRegistry "unstable" { repo = "nixpkgs"; };
            }
            // lib.mapAttrs' (
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
        };

        nixpkgs.config = config.nixpkgs.config;
        networking.hostName = builtins.baseNameOf host;
      })

      "${hostsDir}/${host}/configuration.nix"
    ];
  };
in
builtins.mapAttrs (h: _: mkNixosSystem h) hosts
