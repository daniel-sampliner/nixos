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
  ];

  programs.jujutsu = {
    enable = true;
    package = pkgs.pkgsUnstable.jujutsu;

    settings = {
      git = {
        colocate = false;

        private-commits =
          let
            bookmarks = [ ''bookmarks("*∅*")'' ];

            descriptions =
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
                ];
          in
          lib.trivial.pipe
            [ bookmarks descriptions ]
            [
              builtins.concatLists
              (lib.strings.concatStringsSep " | ")
            ];

        sign-on-push = true;
      };

      revset-aliases = {
        "bough()" = "bough(@)";
        "bough(x)" = "bough(x, trunk())";
        "bough(x, m)" = "descendants(ancestors(x) ~ ancestors(m))";

        "closest_bookmark()" = "closest_bookmark(@)";
        "closest_bookmark(to)" = ''
          coalesce(
            heads(first_ancestors(to) & bookmarks()),
            heads(ancestors(to) & bookmarks()),
          )
        '';

        "closest_pushable()" = "closest_pushable(@)";
        "closest_pushable(to)" = ''
          heads(::to
            & mutable()
            & ~description(exact:"")
            & (~empty() | merges()))
        '';

        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
        "user(x)" = "author(x) | committer(x)";
        "user_email(x)" = "author_email(x) | committer_email(x)";
        "user_name(x)" = "author_name(x) | committer_name(x)";
      };

      revsets = {
        "bookmark-advance-to" = "closest_pushable(@)";
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

      "template-aliases" = {
        "base_git_push_bookmark" = "base_git_push_bookmark()";
        "base_git_push_bookmark()" = "base_git_push_bookmark(default_slug_width)";
        "base_git_push_bookmark(width)" = ''slugify(description, width) ++ "/" ++ change_id.short()'';
        "default_slug_width" = "65";
        "slugify" = "slugify()";
        "slugify()" = "slugify(description)";
        "slugify(str)" = "slugify(str, default_slug_width)";

        "slugify(str, width)" = ''
          coalesce(
            stringify(truncate_end(width, str.first_line()))
              .replace(regex:'[^[[:alnum:]].]', '-')
              .replace(regex:'-{2,}', '-')
              .replace(regex:'\.{2,}', '.')
              .replace(regex:'(^-+|-+$)', ''')
              .lower(),
            "∅"
          )
        '';
      };

      templates = {
        config_list = "builtin_config_list_detailed";

        duplicate_description = ''
          concat(
            description,
            "\n(cherry picked from commit ",
            commit_id,
            ")",
          )
        '';

        git_push_bookmark = ''slugify ++ "/" ++ change_id.short()'';

        new_description = ''
          if(parents.len() > 1,
            "Merge " ++ parents.skip(1).map(|p| try(
              p.bookmarks().first().name(),
              p.change_id().shortest(8)
            )).join(", ") ++ " into " ++ try(
              parents.first().bookmarks().first().name(),
              parents.first().change_id().shortest(8)
            ) ++ "\n",
            ""
          )
        '';
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
