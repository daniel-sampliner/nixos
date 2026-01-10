# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./flakeref.nix
    ./nvim
    ./tug.nix
  ];

  programs.jujutsu = {
    enable = true;
    package = pkgs.pkgsUnstable.jujutsu;

    settings = {
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

      revset-aliases = {
        "bough()" = "bough(@)";
        "bough(x)" = "bough(x, trunk())";
        "bough(x, m)" = "descendants(ancestors(x) ~ ancestors(m))";
        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
        "user(x)" = "author(x) | committer(x)";
        "user_email(x)" = "author_email(x) | committer_email(x)";
        "user_name(x)" = "author_name(x) | committer_name(x)";
      };

      "--scope" = [
        {
          "--when".commands = [ "help" ];

          ui.pager = [
            (lib.getExe pkgs.glow)
            "-p"
          ];
        }
      ];

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
}
