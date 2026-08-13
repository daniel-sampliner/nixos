# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      git-absorb
      ;
  };

  programs.difftastic.enable = true;

  programs.git = {
    enable = true;

    settings = {
      alias = {
        difft = "--paginate difftool --no-prompt --tool difftastic";
      };

      blame.markIgnoredLines = true;
      blame.markUnblamableLines = true;

      branch.sort = "-committerdate";
      core.askPass = "false";
      core.pager = "less -FRi";

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
        tool = "difftastic";
      };

      difftool.difftastic.cmd = "${lib.getExe config.programs.difftastic.package} ${
        lib.cli.toCommandLineShellGNU { } config.programs.difftastic.options
      } $LOCAL $REMOTE";

      fetch.prune = true;
      fetch.fsckObjects = true;

      init.defaultBranch = "main";
      log.date = "iso";
      merge.conflictstyle = "zdiff3";

      notes.rewrite.amend = true;
      notes.rewrite.rebase = true;

      push.autoSetupRemote = true;
      push.default = "upstream";

      rebase.autoSquash = true;
      rebase.missingCommitsCheck = "error";

      rerere.autoUpdate = true;
      rerere.enabled = true;

      receive.fsckObjects = true;
      transfer.fsckObjects = true;
    };
  };
}
