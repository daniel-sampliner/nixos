# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_:
let
  mkAliasAttrs =
    args: cmds:
    builtins.listToAttrs (
      builtins.map (cmd: {
        name = cmd;
        value = "${cmd} ${args}";
      }) cmds
    );
in
{
  home.shellAliases =
    mkAliasAttrs "--color=auto" [
      "clush"
      "dir"
      "diff"
      "dmesg"
      "grep"
      "ls"
      "pw-mon"
      "vdir"
    ]
    // mkAliasAttrs "-color=auto" [
      "bridge"
      "ip"
      "tc"
    ];
}
