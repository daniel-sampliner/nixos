# SPDX-FileCopyrightText: 2024, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pkgs:
let
  inherit (pkgs) lib;
  inherit (pkgs.inputs') git-hooks;

  run = git-hooks.lib.run {
    inherit (pkgs) src;

    hooks = {
      commitizen.enable = true;
      commitizen.package =
        let
          exposedPkg = git-hooks.exposed.tools.commitizen;
          pkg =
            assert lib.strings.versionOlder (lib.strings.getVersion exposedPkg) "4.16.3";
            exposedPkg.overrideAttrs (prev: {
              patches = prev.patches or [ ] ++ [
                (pkgs.fetchpatch {
                  url = "https://github.com/commitizen-tools/commitizen/commit/8e9af1ebc9e8065f9062d03af6e09c300fb3519f.patch";
                  hash = "sha256-gT+CaS8/QLZCSFgs3dOhfcMnUC92a9iG3Ythci3+E9M=";
                })

                (pkgs.fetchpatch {
                  url = "https://github.com/commitizen-tools/commitizen/commit/1090d66646f53da1afa7520163d2adad98f28220.patch";
                  hash = "sha256-iHvdxlmJ+sNUScOOID0ZRAlS5rHatpgMW9jMN4KXRUw=";
                })

                (pkgs.fetchpatch {
                  url = "https://github.com/commitizen-tools/commitizen/commit/2b4707cf04929810d8137f12726abe44e67a220e.patch";
                  hash = "sha256-py7yxVr6ra7WcXYKleebwGjaoJ9yy+KCWrxqrmu0Tlg=";
                })
              ];
            });
        in
        pkg;

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
