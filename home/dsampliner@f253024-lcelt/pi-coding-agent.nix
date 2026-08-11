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
  home.file.".pi/agent/extensions" = {
    source = pkgs.stdenvNoCC.mkDerivation (final: {
      pname = "${lib.strings.getName pi-coding-agent}-example-extensions";
      version = "${lib.strings.getVersion pi-coding-agent}";

      files = [
        "commands.ts"
        "handoff.ts"
        "inline-bash.ts"
        "pirate.ts"
        "session-name.ts"
        "structured-output.ts"
        "tools.ts"
      ];

      src = pi-coding-agent;
      dontUnpack = true;
      dontPatch = true;
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        cd "$src/lib/node_modules/pi-monorepo/examples/extensions" || exit 1

        ${lib.strings.toShellVar "files" final.files}
        install -Dm 0644 -t "$out" "''${files[@]}"

        substitute "notify.ts" "$out/notify-modified.ts" \
          --replace-fail agent_end agent_settled
      '';
    });

    recursive = true;
  };

  home.packages = builtins.attrValues {
    inherit (pkgs) opensrc;
    inherit (pkgs.pkgsExtra) ai-jail;
    inherit (pkgs.pkgsUnstable) nono rtk;
    inherit pi-coding-agent;
  };

  home.sessionVariables = {
    RTK_DB_PATH = "${config.xdg.dataHome}/rtk/history.db";
  };

  programs.neovim.initLua = lib.mkOrder 1 ''
    if os.getenv("NONO_CAP_FILE") then
      vim.opt.shadafile = "NONE"
      vim.opt.swapfile = false
    end
  '';
}
