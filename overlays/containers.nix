# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: prev:
let
  inherit (prev) lib;
in
{
  dockerTools =
    let
      dt = prev.dockerTools;
    in
    dt
    // {
      caCertificates = dt.caCertificates.overrideAttrs (prev': {
        buildInputs = prev'.buildInputs or [ ] ++ [ prev.cacert ];
      });
    };

  nix2container =
    let
      n2c = prev.fp.inputs'.nix2container.packages.nix2container;

      inherit (prev.fp.self) sourceInfo;

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
          repository = "ghcr.io/${repo}/${args.name}";

          defaultArgs = {
            config.Labels = {
              "org.opencontainers.image.created" = isoDate;
              "org.opencontainers.image.source" = "https://github.com/${repo}";
              "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
            }
            // lib.attrsets.optionalAttrs (rev != null) { "org.opencontainers.image.revision" = rev; };

            created = isoDate;
            maxLayers = 125 - (builtins.length args.layers or [ ]);

            meta = {
              inherit (args) tag;
              inherit repository;

              tags =
                let
                  splitTag = lib.versions.splitVersion args.tag;
                  head = builtins.head splitTag;
                  tail = builtins.tail splitTag;
                in
                builtins.foldl' (x: y: [ "${builtins.head x}.${y}" ] ++ x) [ head ] tail
                ++ [
                  "latest"
                  (lib.strings.removePrefix "/" (builtins.placeholder "out"))
                ];
            };
          };

          overrideArgs = {
            name = repository;
          };
        in
        n2c.buildImage (
          builtins.foldl' lib.attrsets.recursiveUpdate defaultArgs [
            args
            overrideArgs
          ]
        );
    in
    n2c // { buildImage = buildImage'; };

  writers = prev.writers // {
    writeExecline =
      {
        flags ? "-WP",
        runtimeInputs ? [ ],
      }:
      nameOrPath: content:
      prev.writers.makeScriptWriter {
        interpreter =
          lib.getExe' prev.execline "execlineb" + lib.strings.optionalString (flags != "") (" " + flags);
        makeWrapperArgs = lib.lists.optionals (runtimeInputs != [ ]) [
          "--prefix"
          "PATH"
          ":"
          (lib.strings.makeBinPath runtimeInputs)
        ];
      } nameOrPath content;
  };
}
