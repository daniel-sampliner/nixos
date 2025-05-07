# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

final: prev:
let
  inherit (prev) lib;
  inherit (prev.flakePackages) self;
in
{
  dockerTools = builtins.mapAttrs (
    _: v:
    if (lib.attrsets.isDerivation v && v ? buildCommand && v.buildCommand != "") then
      prev.runCommand v.name { } ''
        cp -Lrv -- "${v.outPath}" "$out"
      ''
    else
      v
  );

  nix2container.buildImage =
    buildImage:
    let
      inherit (self) sourceInfo;

      date = sourceInfo.lastModifiedDate or "19700101000001";
      year = lib.substring 0 4 date;
      month = lib.substring 4 2 date;
      day = lib.substring 6 2 date;
      hour = lib.substring 8 2 date;
      minute = lib.substring 10 2 date;
      second = lib.substring 12 2 date;

      isoDate = "${year}-${month}-${day}T${hour}:${minute}:${second}+00:00";

      repo = "daniel-sampoliner/nixos";
      rev = sourceInfo.rev or sourceInfo.dirtyRev or null;

    in
    {
      name,
      tag ? null,
      maxLayers ? 125 - (builtins.length layers),
      layers ? [ ],
      config ? { },
      created ? isoDate,
      meta ? { },
      ...
    }@args:
    let
      repository = "ghcr.io/${repo}/${name}";
    in
    buildImage (
      args
      // {
        inherit
          tag
          maxLayers
          layers
          created
          ;

        name = repository;

        config = lib.attrsets.recursiveUpdate {
          Labels = {
            "org.opencontainers.image.created" = isoDate;
            "org.opencontainers.image.source" = "https://github.com/${repo}";
            "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
          } // lib.attrsets.optionalAttrs (rev != null) { "org.opencontainers.image.revision" = rev; };
        } config;

        meta = lib.attrsets.recursiveUpdate {
          inherit repository tag;

          tags =
            let
              splitTag = lib.strings.splitString "." tag;
              head = builtins.head splitTag;
              tail = builtins.tail splitTag;

              tags =
                builtins.foldl' (x: y: [ "${builtins.head x}.${y}" ] ++ x) [
                  head
                ] tail
                ++ [ "latest" ];
            in
            lib.lists.optionals (tag != null) tags;
        } meta;
      }
    );
}
