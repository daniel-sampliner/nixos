# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  flakelight,
  inputs,
  lib,
  moduleArgs,
  ...
}:
{
  options =
    let
      types = lib.types // flakelight.types;
    in
    {
      containers = lib.mkOption {
        type = types.nullable (types.optFunctionTo (types.lazyAttrsOf types.packageDef));
        default = null;
      };

      containerOverlay = lib.mkOption {
        internal = true;
        type = types.uniq types.overlay;
        default = _: _: { };
      };
    };

  config.outputs =
    let
      cfg = config.containers;

      genSystemsUnstable = f: lib.genAttrs config.systems (system: f ctrsFor.${system});
      ctrsFor = lib.genAttrs config.systems (
        system:
        import inputs.unstable {
          inherit system;
          inherit (config.nixpkgs) config;
          overlays = config.withOverlays ++ [ config.packageOverlay ];
        }
      );

      genCtr =
        pkgs: name: pkg:
        let
          args = lib.functionArgs pkg;
          noArgs = args == { };
          pkg' = if noArgs then { pkgs }: pkg pkgs else pkg;
          dependsOnSelf = builtins.hasAttr name args;
          dependsOnPkgs = noArgs || (args ? pkgs);
          selfOverride = {
            ${name} = pkgs.${name} or (throw "${name} depends on ${name}, but no existing ${name}.");
          };
          overrides =
            lib.optionalAttrs dependsOnSelf selfOverride
            // lib.optionalAttrs dependsOnPkgs { pkgs = pkgs // selfOverride; };
        in
        pkgs.callPackage pkg' overrides;

      getCtrDefs = pkgs: cfg (moduleArgs // { inherit (pkgs) system; });

      containers = genSystemsUnstable (pkgs: builtins.mapAttrs (k: v: genCtr pkgs k v) (getCtrDefs pkgs));
    in
    lib.mkIf (cfg != null) {
      inherit containers;

      checks = builtins.mapAttrs (_: lib.mapAttrs' (n: lib.nameValuePair "containers-${n}")) containers;
    };
}
