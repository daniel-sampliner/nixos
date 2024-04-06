# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

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
