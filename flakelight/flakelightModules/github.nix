# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  outputs,
  src,
  ...
}:
{
  config.outputs.github = lib.genAttrs config.systems (system: {
    checks = lib.pipe outputs.checks.${system} [
      builtins.attrNames
      (builtins.filter (n: !lib.hasPrefix "containers-" n))
      (builtins.filter (n: !lib.hasPrefix "nixos-" n))
      (builtins.map (n: ".#checks.${system}.${n}"))
    ];

    containers = lib.pipe outputs.containers.${system} [
      builtins.attrNames
      (builtins.map (n: ".#containers.${system}.${n}"))
    ];

    cachixPushFilter =
      let
        unfree = builtins.map (pkg: ".*-${pkg}-.*") config.nixpkgs-config.unfreePkgs;

        extraExcludes = lib.pipe outputs.checks [
          (lib.collect lib.isDerivation)

          (builtins.filter (
            c:
            builtins.elem (lib.getName c) [
              "check-formatting"
              "pre-commit-run"
            ]
          ))

          (builtins.map (c: c.outPath))
          (builtins.map lib.escapeRegex)
        ];
      in
      "^(" + lib.concatStringsSep "|" (unfree ++ extraExcludes) + ")$\n";

    updateables = lib.pipe outputs.packages.${system} [
      (lib.attrsets.filterAttrs (_: pkg: (pkg.passthru or { }) ? updateScript))
      (lib.attrsets.mapAttrsToList (
        name: pkg:
        let
          inherit (pkg.passthru) updateScript;
        in
        {
          inherit name;

          updateScript = builtins.map (builtins.replaceStrings
            [ (builtins.toString src) ]
            [ "/homeless-shelter/" ]
          ) updateScript;

          build =
            let
              parts = builtins.match "(/nix/store/[^/]+)/.*" (builtins.head updateScript);
            in
            builtins.head parts;
        }
      ))
    ];
  });
}
