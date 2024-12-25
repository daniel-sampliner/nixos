# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  outputs,
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
        notRedistributables =
          let
            isRedistributable =
              pkg: lib.lists.any (l: l.redistributable or false) (lib.lists.toList (pkg.meta.license or [ ]));

            notRedistributable = pkg: !isRedistributable pkg;

            packagesWith =
              cond: arg:
              let
                res = builtins.tryEval (
                  if lib.isDerivation arg then
                    lib.optional (cond arg) arg.outPath
                    ++ builtins.map (packagesWith cond) (arg.buildInputs or [ ] ++ arg.propagatedBuildInputs or [ ])
                  else if lib.isAttrs arg then
                    builtins.mapAttrs (_: arg': packagesWith cond arg') arg
                  else
                    [ ]
                );
              in
              lib.optionals res.success res.value;

          in
          lib.pipe (packagesWith notRedistributable outputs.packages.${system}) [
            (lib.collect (x: builtins.isList x && x != [ ]))
            lib.flatten
            lib.unique
            (builtins.map lib.escapeRegex)
          ];

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
      "^(" + lib.concatStringsSep "|" (notRedistributables ++ extraExcludes ++ unfree) + ")$\n";
  });
}
