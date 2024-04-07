# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = builtins.attrValues { inherit (pkgs) difftastic git-absorb; };

  programs.git = {
    enable = true;

    aliases = {
      difft = "--paginate difftool --no-prompt --tool difftastic";
    };

    attributes = [ "*.go  -text  diff=golang" ];

    extraConfig = {
      blame = {
        markIgnoredLines = true;
        markUnblamableLines = true;
      };

      branch.sort = "-committerdate";
      commit.cleanup = "scissors";
      core.askpass = "true";

      credential.helper =
        let
          cache =
            pkgs.writers.makeScriptWriter { interpreter = "${lib.getExe' pkgs.execline "execlineb"} -WS0"; }
              "/bin/systemd-git-credential-cache"
              ''
                backtick -E uuid { redirfd -r 0 /proc/sys/kernel/random/uuid
                  tr -dc "[:xdigit:]" }

                systemd-run
                  --scope
                  --unit=app-git-credential-cache-$uuid
                  --slice=app-git_credential_cache
                  --quiet
                  --user

                  ${config.programs.git.package}/libexec/git-core/git-credential-cache
                  $@
              '';
        in
        lib.mkBefore [ "${lib.getExe cache} --timeout 21600" ];

      credential.useHttpPath = true;

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
      };

      difftool.difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
      fetch.prune = true;
      init.defaultBranch = "main";
      log.date = "iso";
      merge.conflictstyle = "zdiff3";

      notes.rewrite.amend = true;
      notes.rewrite.rebase = true;

      push.autoSetupRemote = true;
      push.default = "upstream";

      rebase = {
        autoSquash = true;
        missingCommitsCheck = "error";
        updateRefs = true;
      };

      rerere.autoUpdate = true;
      rerere.enabled = true;

      url."https://github.com/".insteadOf = [
        "git@github.com:"
        "ssh://git@github.com:"
        "ssh://git@github.com/"
      ];

      fetch.fsckobjects = true;
      receive.fsckObjects = true;
      transfer.fsckobjects = true;
    };
  };

  programs.git-credential-oauth.enable = true;
}
