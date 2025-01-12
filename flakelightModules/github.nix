# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
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
  config.outputs.github = lib.genAttrs config.systems (
    system:
    let
      drvChecks = lib.filterAttrs (_: v: lib.isDerivation v) outputs.checks.${system};

      containers = lib.filterAttrs (n: _: lib.hasPrefix "containers-" n) drvChecks;
      homes = lib.filterAttrs (_: v: lib.getName v == "home-manager-generation") drvChecks;
      nixoss = lib.filterAttrs (n: _: lib.hasPrefix "nixos-" n) drvChecks;

      checks = lib.filterAttrs (
        n: _: !builtins.elem n (builtins.attrNames (containers // homes // nixoss))
      ) drvChecks;
    in
    {
      inherit
        containers
        homes
        nixoss
        checks
        ;

      cachixPushFilter =
        let
          unfree = builtins.map (pkg: ".*-${pkg}-.*") config.nixpkgs-config.unfreePkgs;

          extraExcludes = lib.pipe drvChecks [
            builtins.attrValues

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
    }
  );
}
