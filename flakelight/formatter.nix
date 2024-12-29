# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pkgs:
let
  inherit (pkgs) lib;
  inherit (pkgs.inputs) treefmt-nix;

  mod = treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    programs = {
      nixfmt.enable = true;

      shfmt.enable = true;
      shfmt.indent_size = null;

      taplo.enable = true;

      yamlfmt.enable = true;
    };

    settings.formatter = {
      nixfmt.excludes = [ "hardware-configuration.nix" ];

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
  };
in
lib.attrsets.recursiveUpdate mod.config.build.wrapper { passthru.moduleArgs = mod; }
