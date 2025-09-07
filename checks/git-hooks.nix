# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pkgs:
let
  inherit (pkgs.inputs') git-hooks;
  run = git-hooks.lib.run {
    inherit (pkgs) src;

    hooks = {
      commitizen.enable = true;

      deadnix.enable = true;
      deadnix.settings.edit = true;

      editorconfig-checker.enable = true;
      nil.enable = true;
      shellcheck.enable = true;
      statix.enable = true;
      end-of-file-fixer.enable = true;
      reuse.enable = true;

      treefmt.enable = true;
      treefmt.package = pkgs.outputs'.formatter;
    };
  };
in
run.overrideAttrs (prev: {
  buildPhase = ''
    {
      echo .cache/pre-commit
      echo .gitconfig
    } >>.gitignore
  ''
  + prev.buildPhase;
})
// {
  inherit (run) config shellHook;
  inherit (run.config) enabledPackages;
}
