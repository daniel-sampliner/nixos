# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: prev:
let
  lib = prev.lib.extend (_: _: prev.outputs.lib);
in
{
  inherit lib;

  dockerTools = builtins.mapAttrs (
    _: v:
    if lib.isDerivation v && v.buildCommand or "" != "" then
      prev.runCommand v.name { } ''
        cp -Lr -- "${v.outPath}" "$out"
      ''
    else
      v
  ) prev.dockerTools;

  nix2container =
    let
      inherit (prev.inputs'.nix2container.packages) nix2container;
      inherit (prev.inputs.self) sourceInfo;

      date = sourceInfo.lastModifiedDate or "19700101000001";
      year = lib.substring 0 4 date;
      month = lib.substring 4 2 date;
      day = lib.substring 6 2 date;
      hour = lib.substring 8 2 date;
      minute = lib.substring 10 2 date;
      second = lib.substring 12 2 date;

      isoDate = "${year}-${month}-${day}T${hour}:${minute}:${second}+00:00";

      rev = sourceInfo.rev or sourceInfo.dirtyRev or null;

      buildImage' =
        args:
        let
          repo = "daniel-sampliner/nixos";

          args' =
            let
              repository = "ghcr.io/${repo}/${args.name}";
            in
            args
            // {
              name = repository;
              maxLayers = args.maxLayers or 125 - (builtins.length args.layers or [ ]);

              config = prev.lib.recursiveUpdate {
                Labels = {
                  "org.opencontainers.image.created" = isoDate;
                  "org.opencontainers.image.source" = "https://github.com/${repo}";
                  "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
                } // lib.optionalAttrs (rev != null) { "org.opencontainers.image.revision" = rev; };
              } args.config or { };

              created = args.created or isoDate;

              meta = prev.lib.recursiveUpdate {
                inherit (args) tag;
                inherit repository;

                tags =
                  let
                    splitTag = lib.splitString "." args.tag;
                    head = builtins.head splitTag;
                    tail = builtins.tail splitTag;
                  in
                  builtins.foldl' (x: y: [ "${builtins.head x}.${y}" ] ++ x) [ head ] tail ++ [ "latest" ];
              } args.meta or { };
            };
        in
        nix2container.buildImage args';
    in
    nix2container // { buildImage = buildImage'; };

  noopPkg = pkg: prev.emptyFile.overrideAttrs { name = "${lib.getName pkg}-${lib.getVersion pkg}"; };

  vimPlugins = prev.vimPlugins.extend (
    _: _: lib.filterAttrs (_: v: lib.strings.hasPrefix "vimplugin-" v.name) prev.outputs'.packages
  );

  writers = prev.writers // prev.callPackage ./withOverlays/writers.nix { };
}
