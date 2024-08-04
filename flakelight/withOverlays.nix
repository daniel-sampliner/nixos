# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: prev: {
  nix2container =
    let
      inherit (prev) lib;
      inherit (prev.inputs'.nix2container.packages) nix2container;
      inherit (prev.inputs.self) sourceInfo;

      date = sourceInfo.lastModifiedDate or "19700101000001";
      year = lib.substring 0 4 date;
      month = lib.substring 4 2 date;
      day = lib.substring 6 2 date;
      hour = lib.substring 8 2 date;
      minute = lib.substring 10 2 date;
      second = lib.substring 12 2 date;

      rev = sourceInfo.rev or sourceInfo.dirtyRev or null;

      buildImage' =
        args:
        let
          repo = "daniel-sampliner/nixos";

          args' = args // {
            name = "ghcr.io/${repo}/${args.name}";
            maxLayers = args.maxLayers or 125;

            config = prev.lib.recursiveUpdate {
              Labels = {
                "org.opencontainers.image.created" = "${year}-${month}-${day}T${hour}:${minute}:${second}+00:00";
                "org.opencontainers.image.source" = "https://github.com/${repo}";
                "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
              } // lib.optionalAttrs (rev != null) { "org.opencontainers.image.revision" = rev; };
            } args.config or { };

            meta = prev.lib.recursiveUpdate { inherit (args) tag; } args.meta or { };
          };
        in
        nix2container.buildImage args';
    in
    nix2container // { buildImage = buildImage'; };
}