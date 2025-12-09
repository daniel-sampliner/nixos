# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:
{
  programs.jujutsu.settings.aliases.flakeref =
    let
      shell = lib.getExe pkgs.dash;

      script = pkgs.writeTextFile {
        name = "jj-flakeref";
        executable = true;

        text = ''
          #!${shell}
          set -eu

          git_root="$(jj git root)"
          git_ref="$(jj show -T commit_id --no-patch "''${1:-@}")"
          echo "git+file://''${git_root:?}?ref=refs/jj/keep/''${git_ref:?}"
        '';

        checkPhase = ''
          runHook preCheck
          ${shell} -n "$target"
          ${lib.getExe pkgs.shellcheck-minimal} "$target"
          runHook postCheck
        '';
      };
    in
    [
      "util"
      "exec"
      "--"
      "${script}"
    ];
}
