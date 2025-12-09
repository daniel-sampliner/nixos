# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: {
  programs.jujutsu.settings = {
    aliases.tug = [
      "bookmark"
      "move"
      "--from"
      "closest_bookmark(@)"
      "--to"
      "closest_pushable(@)"
    ];

    revset-aliases = {
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
    };
  };
}
