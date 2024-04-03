# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ config, lib, ... }:
let
  cfg = config.simpleBTRFS;
in
{
  options.simpleBTRFS =
    let
      inherit (lib) types;

      mount =
        { name, ... }:
        {
          options = {
            atime = lib.mkOption {
              default = "noatime";
              description = "`atime` mount option; see {manpage}`mount(8)` for details.";
              type = types.enum [
                "strictatime"
                "noatime"
              ];
            };
            mountPoint = lib.mkOption {
              default = name;
              description = "Location of the mounted file system.";
              example = "/mnt/foo";
              type = types.path;
            };
            neededForBoot = lib.mkOption {
              default = true;
              description = "Whether this mount is needed for boot.";
              type = types.bool;
            };
            subvolume = lib.mkOption {
              description = "The subvolume to mount.";
              example = "@foo";
              type = types.str;
            };
          };
        };
    in
    {
      enable = lib.mkEnableOption "simple BTRFS filesystem layout";

      defaultMounts = lib.mkOption {
        default = {
          "/" = {
            subvolume = "@root";
          };
          "/nix" = {
            subvolume = "@nix";
          };
          "/var/log" = {
            subvolume = "@log";
          };
          "/home" = {
            atime = "strictatime";
            subvolume = "@home";
          };
        };
        type = types.attrsOf (types.submodule mount);
        visible = false;
      };

      mounts = lib.mkOption {
        default = { };
        description = "Attribute set mapping mountpoints to their respective subvolume.";
        example = {
          "/foo".subvolume = "@foo";
        };

        type = types.attrsOf (types.submodule mount);
      };
    };

  config =
    let
      mkFileSystem = _: spec: {
        inherit (spec) neededForBoot;

        fsType = "btrfs";
        label = "root";
        options = btrfsOptions spec;
      };

      btrfsOptions = spec: [
        "${spec.atime}"
        "autodefrag"
        "compress=zstd"
        "discard=async"
        "lazytime"
        "space_cache=v2"
        "subvol=${spec.subvolume}"
        "user_subvol_rm_allowed"
      ];
    in
    lib.mkIf cfg.enable {
      fileSystems = builtins.mapAttrs mkFileSystem (cfg.defaultMounts // cfg.mounts);

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ "/" ];
        interval = "weekly";
      };
    };
}
