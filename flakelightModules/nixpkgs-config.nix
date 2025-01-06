# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, lib, ... }:
{
  options.nixpkgs-config =
    let
      inherit (lib) types;
    in
    {
      unfreePkgs = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "nvidia-settings"
          "nvidia-x11"
          "pritunl-client"
        ];
      };
    };

  config =
    let
      cfg = config.nixpkgs-config;
    in
    {
      nixpkgs.config = {
        allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.unfreePkgs;

        # Workaround for Dotnet SDK 6.x EOL
        allowInsecurePredicate =
          pkg:
          builtins.elem (lib.getName pkg) (
            lib.concatMap
              (n: [
                n
                "${n}-wrapped"
              ])
              [
                "aspnetcore-runtime"
                "dotnet-sdk"
              ]
          )
          && lib.hasPrefix "6." (lib.getVersion pkg);
      };
    };
}
