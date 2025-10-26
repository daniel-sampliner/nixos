# SPDX-FileCopyrightText: 2025 Daniel Sampliner <dsampliner@f253024-lcelt.liger-beaver.ts.net>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.jujutsu = {
    enable = true;
    package = pkgs.pkgsUnstable.jujutsu;

    settings =
      let
        nvim_args = [
          "--cmd"
          "let g:flatten_wait=1"
        ];
      in
      {
        aliases = {
          "flakeref" =
            let
              shell = lib.getExe pkgs.dash;

              script = pkgs.writeTextFile {
                name = "jj-flakeref";
                executable = true;

                text = ''
                  #!${shell}
                  set -eu

                  git_root="$(jj git root)"
                  git_ref="$(jj show -T commit_id --no-patch "''${1:-@}")"
                  echo "git+file://''${git_root:?}?ref=refs/jj/keep/''${git_ref:?}"
                '';

                checkPhase = ''
                  runHook preCheck
                  ${shell} -n "$target"
                  ${lib.getExe pkgs.shellcheck-minimal} "$target"
                  runHook postCheck
                '';
              };
            in
            [
              "util"
              "exec"
              "--"
              "${script}"
            ];
        };

        git = {
          colocate = false;

          private-commits =
            lib.trivial.pipe
              [
                "wip"
                "private"
              ]
              [
                (builtins.map (p: [
                  "${p}:"
                  "${p}("
                ]))
                lib.lists.flatten
                (builtins.map (p: ''description(glob-i:"${p}*")''))
                (lib.strings.concatStringsSep " | ")
              ];

          sign-on-push = true;
        };

        merge-tools = {
          hunk = {
            program = "nvim";
            diff-args = [ ];

            edit-args = nvim_args ++ [
              "-c"
              "DiffEditor $left $right $output"
            ];
          };

          nvim = {
            program = pkgs.execline.passthru.writeScript "jj-nvim-shim" "-WS2" (
              builtins.readFile ./jj-nvim-shim
            );

            diff-args = [ ];
            edit-args = [
              "$left"
              "$right"
            ]
            ++ nvim_args;
          };

          nvimdiff = {
            program = "nvim";
            diff-args = [ ];

            edit-args = nvim_args ++ [
              "-d"
              "$left"
              "$right"
            ];

            merge-args = nvim_args ++ [
              "-d"
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

        revset-aliases = {
          "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
        };

        templates = {
          config_list = "builtin_config_list_detailed";
        };

        ui = {
          editor = lib.mkIf config.programs.neovim.defaultEditor ([ "nvim" ] ++ nvim_args);

          pager = {
            command = [
              "less"
              "-FR"
            ];
            env.LESSCHARSET = "utf-8";
          };
        };
      };
  };

  programs.neovim.plugins =
    let
      pluginConfigs = lib.trivial.pipe ./. [
        (lib.fileset.fileFilter ({ type, hasExt, ... }: type == "regular" && hasExt "lua"))
        lib.fileset.toList
        (builtins.map (f: {
          plugin = lib.trivial.pipe f [
            builtins.baseNameOf
            (lib.strings.removeSuffix ".lua")
            (lib.trivial.flip builtins.getAttr pkgs.vimPlugins)
          ];

          config = "luafile ${f}";
        }))
      ];
    in
    builtins.attrValues {
      inherit (pkgs.vimPlugins)
        nui-nvim
        vim-jjdescription
        ;
    }
    ++ pluginConfigs;
}
