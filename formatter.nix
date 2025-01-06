# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pkgs:
let
  inherit (pkgs) lib;
  inherit (pkgs.inputs) treefmt-nix;
  inherit (pkgs.inputs') unstable;

  mod = treefmt-nix.lib.evalModule unstable.legacyPackages {
    projectRootFile = "flake.nix";

    programs = {
      jsonfmt.enable = true;
      nixfmt.enable = true;

      shfmt.enable = true;
      shfmt.indent_size = null;

      taplo.enable = true;
      yamlfmt.enable = true;
    };

    settings = {
      on-unmatched = "info";

      formatter = {
        nixfmt.excludes = [ "**/hardware-configuration.nix" ];

        yamlfmt.options =
          let
            cfg = pkgs.writers.writeYAML "yamlfmt.yaml" {
              formatter = {
                type = "basic";
                retain_line_breaks_single = true;
                scan_folded_as_literal = true;
                trim_trailing_whitespace = true;
              };
            };
          in
          [
            "-conf"
            cfg.outPath
          ];
      };

      global.excludes = [
        "*.license"
        "*.sops"
        "*.zsh"
        "*_key"
        "*_key.pub"
        ".editorconfig"
        ".gitattributes"
        "LICENSE.md"
        "LICENSES/*"
      ];
    };
  };
in
lib.attrsets.recursiveUpdate mod.config.build.wrapper { passthru.moduleArgs = mod; }
