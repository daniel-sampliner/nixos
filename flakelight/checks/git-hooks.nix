# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

pkgs:
pkgs.inputs'.git-hooks.lib.run {
  inherit (pkgs) src;

  hooks = {
    commitizen.enable = true;

    deadnix.enable = true;
    deadnix.settings.edit = true;

    editorconfig-checker.enable = true;
    nil.enable = true;
    shellcheck.enable = true;
    statix.enable = true;

    end-of-file-fixer =
      let
        inherit (pkgs.python3Packages) pre-commit-hooks;
      in
      {
        enable = true;
        entry = "${pre-commit-hooks}/bin/end-of-file-fixer";
        name = "fix end of files";
        package = pre-commit-hooks;
        stages = [
          "commit"
          "push"
          "manual"
        ];
        types = [ "text" ];
      };

    reuse = {
      enable = true;
      name = "REUSE spec compliance";
      entry = "${pkgs.reuse}/bin/reuse lint";
      pass_filenames = false;
      package = pkgs.reuse;
    };

    treefmt.enable = true;
    treefmt.package = pkgs.outputs'.formatter;
  };
}
