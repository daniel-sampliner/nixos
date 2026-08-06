# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
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
        "tools.ts"
      ];

      subagent =
        let
          dir = "${srcDir}/subagent";
        in
        {
          agents = {
            source = pkgs.runCommand "pi-subagent-agents" { } ''
              for f in "${dir}/agents"/*.md; do
                install -Dm0644 -t "$out" "$f"
              done

              substituteInPlace "$out/planner.md" \
                --replace-fail 'claude-sonnet-4-5' 'openai-codex/gpt-5.6-sol:high'

              substituteInPlace "$out/reviewer.md" \
                --replace-fail 'claude-sonnet-4-5' 'anthropic/claude-opus-5:high'

              substituteInPlace "$out/scout.md" \
                --replace-fail 'claude-haiku-4-5' 'openai-codex/gpt-5.6-luna:low'

              substituteInPlace "$out/worker.md" \
                --replace-fail 'claude-sonnet-4-5' 'openai-codex/gpt-5.6-terra:medium'
            '';
            recursive = true;
          };

          "extensions/subagent" = {
            source = pkgs.runCommand "pi-subagent-extension" { } ''
              install -Dm0644 -t "$out" "${dir}"/{agents,index}.ts
            '';
            recursive = false;
          };

          prompts = {
            source = "${dir}/prompts";
            recursive = true;
          };
        };

      dstDir = ".pi/agent";
    in
    lib.trivial.pipe extensions [
      (builtins.map (
        ext: lib.attrsets.nameValuePair "${dstDir}/extensions/${ext}" { source = "${srcDir}/${ext}"; }
      ))
      builtins.listToAttrs
    ]
    // lib.attrsets.mapAttrs' (
      name: value: lib.attrsets.nameValuePair "${dstDir}/${name}" value
    ) subagent;

  home.packages = builtins.attrValues {
    inherit (pkgs) opensrc;
    inherit (pkgs.pkgsExtra) ai-jail;
    inherit (pkgs.pkgsUnstable) nono rtk;
    inherit pi-coding-agent;
  };

  home.sessionVariables = {
    RTK_DB_PATH = "${config.xdg.dataHome}/rtk/history.db";
  };
}
