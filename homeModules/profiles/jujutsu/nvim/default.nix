# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.jujutsu.settings =
    let
      nvim_cmd = lib.getExe config.programs.neovim.finalPackage;
      nvim_args = [
        "--cmd"
        "let g:flatten_wait=1"
      ];
    in
    {
      merge-tools = {
        hunk = {
          program = nvim_cmd;
          diff-args = [ ];

          edit-args = nvim_args ++ [
            "-c"
            "DiffEditor $left $right $output"
          ];
        };

        nvim = {
          program =
            (pkgs.execline.passthru.writeScript "jj-nvim-shim" "-WS2" (builtins.readFile ./jj-nvim-shim))
            .overrideAttrs
              (prev: {
                buildCommand = prev.buildCommand + ''
                  substituteInPlace "$out" \
                    --replace-fail "nvim" "${nvim_cmd}"
                '';
              });

          diff-args = [ ];
          edit-args = nvim_args ++ [
            "$left"
            "$right"
          ];
        };

        nvimdiff = {
          program = nvim_cmd;
          diff-args = [ ];

          edit-args = nvim_args ++ [
            "-d"
            "$left"
            "$right"
          ];

          merge-args = nvim_args ++ [
            "-d"
            "$output"
            "-M"
            "$left"
            "$base"
            "$right"
            "-c"
            "wincmd J"
            "-c"
            "set modifiable"
            "-c"
            "set write"
            "-c"
            "/<<<<<</+2"
          ];
          merge-tool-edits-conflict-markers = true;
        };
      };

      ui.editor = lib.mkIf config.programs.neovim.defaultEditor ([ nvim_cmd ] ++ nvim_args);
    };

  programs.neovim.extraPackages = [ pkgs.commitmsgfmt ];

  programs.neovim.plugins = builtins.attrValues {
    inherit (pkgs.vimPlugins)
      nui-nvim
      vim-jjdescription
      ;
  };

  programs.neovim.runtimeDir = [ ./. ];
}
