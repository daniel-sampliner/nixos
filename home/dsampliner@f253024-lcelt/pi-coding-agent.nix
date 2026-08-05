# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  inherit (pkgs.pkgsUnstable) pi-coding-agent;
in
{
  home.file =
    let
      srcDir = "${pi-coding-agent}/lib/node_modules/pi-monorepo/examples/extensions";
      extensions = [
        "commands.ts"
        "handoff.ts"
        "inline-bash.ts"
        "notify.ts"
        "pirate.ts"
        "plan-mode"
        "session-name.ts"
        "structured-output.ts"
        "subagent"
        "tools.ts"
      ];

      dstDir = ".pi/agent/extensions";
    in
    lib.trivial.pipe extensions [
      (builtins.map (ext: lib.attrsets.nameValuePair "${dstDir}/${ext}" { source = "${srcDir}/${ext}"; }))
      builtins.listToAttrs
    ];

  home.packages = builtins.attrValues {
    inherit (pkgs) opensrc;
    inherit (pkgs.pkgsExtra) ai-jail;
    inherit (pkgs.pkgsUnstable) rtk;
    inherit pi-coding-agent;
  };
}
