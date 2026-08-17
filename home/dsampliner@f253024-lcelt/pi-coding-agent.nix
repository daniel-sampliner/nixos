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
  nono = pkgs.pkgsExtra.nono-latest;
  nono-completions = pkgs.pkgsExtra.nono-completions.override { inherit nono; };
  opensrcDir = "${config.xdg.cacheHome}/opensrc";
  pi-coding-agent = pkgs.pkgsUnstable.pkgsExtra.pi-coding-agent-chatgpt-account-id;
  rtkDbDir = "${config.xdg.dataHome}/rtk";
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
      '';
    });

    recursive = true;
  };

  home.packages = builtins.attrValues {
    inherit (pkgs) commitmsgfmt opensrc;
    inherit (pkgs.pkgsExtra) ai-jail;
    inherit (pkgs.pkgsUnstable) rtk;
    inherit nono nono-completions pi-coding-agent;
  };

  home.sessionVariables = {
    OPENSRC_HOME = opensrcDir;
    RTK_DB_PATH = "${rtkDbDir}/history.db";
  };

  programs.neovim.initLua = lib.mkOrder 1 ''
    if os.getenv("NONO_CAP_FILE") then
      vim.opt.shadafile = "NONE"
      vim.opt.swapfile = false
    end
  '';

  systemd.user = {
    services."nono-session-cleanup".Service = {
      ExecStart = "${lib.getExe nono} session cleanup --silent --older-than 7";
      Type = "oneshot";
    };

    timers."nono-session-cleanup" = {
      Timer = {
        OnCalendar = "*-*-* 03:00:00";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    tmpfiles.rules = [
      "d ${opensrcDir} 0700 - - 30d"
      "d ${rtkDbDir}/tee 0700 - - 7d"
      "d %h/.pi/agent/sessions 0700 - - 30d"
    ];
  };
}
