# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      git-absorb
      ;
  };

  programs.git = {
    aliases = {
      difft = "--paginate difftool --no-prompt --tool difftastic";
    };

    difftastic.enableAsDifftool = true;
    enable = true;

    extraConfig = {
      blame.markIgnoredLines = true;
      blame.markUnblamableLines = true;

      branch.sort = "-committerdate";
      core.askPass = "false";

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
      };

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
