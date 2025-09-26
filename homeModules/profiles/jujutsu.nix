# SPDX-FileCopyrightText: 2025 Daniel Sampliner <dsampliner@f253024-lcelt.liger-beaver.ts.net>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
{
  programs.jujutsu = {
    enable = true;

    settings = {
      git = {
        private-commits =
          [
            "wip"
            "private"
          ]
          |> builtins.map (p: [
            "${p}:"
            "${p}("
          ])
          |> lib.lists.flatten
          |> builtins.map (p: ''description(glob-i:"${p}*")'')
          |> lib.strings.concatStringsSep " | ";
        sign-on-push = true;
      };

      revset-aliases = {
        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
      };

      templates = {
        config_list = "builtin_config_list_detailed";
      };

      ui = {
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

  programs.neovim.plugins = [ pkgs.vimPlugins.vim-jjdescription ];
}
