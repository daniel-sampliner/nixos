# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sopsYAML;

  buildVMKey = "age1vc7sqg3w2njy4r8awqsqf2vce8s9g5hp2kx2gue6dyavppd0wu4sh45w6z";
  pgp = "CA85F176F354CC70508D6CC03E9DB066BFDC4A84";

  hostKeys = {
    thiccpad = "age1m3zxw4mjty2ckd06g7mghdmf36n7qcd0xqljljjjer8h836maa8qf5tgmm";
  };

  settings.creation_rules =
    [
      {
        inherit pgp;
        path_regex = ''(^|/)build-vm\.'';
        age = buildVMKey;
      }
    ]
    ++
      builtins.map
        (path_regex: {
          inherit path_regex pgp;
          age = lib.pipe hostKeys [
            builtins.attrValues
            (lib.concatStringsSep " ")
          ];
        })
        [
          "^nixos/profiles/"
          "^nixos/users/"
        ]
    ++ builtins.map (host: {
      inherit pgp;
      path_regex = "^nixos/${host}/";
      age = hostKeys.${host};
    }) (builtins.attrNames hostKeys)
    ++ [ { inherit pgp; } ];

  settingsFormat = pkgs.formats.yaml { };
in
{
  options.sopsYAML = {
    enable = lib.mkEnableOption "generating repo .sops.yaml" // {
      default = true;
    };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = settings;
      description = ''
        Contents of the generated {file}`.sops.yaml`. See
        [upstream](https://github.com/getsops/sops?tab=readme-ov-file#using-sopsyaml-conf-to-select-kms-pgp-and-age-for-new-files)
        for more information.
      '';
    };
  };

  config.devshell.startup = lib.mkIf cfg.enable {
    sopsYAML.text =
      let
        rendered = settingsFormat.generate "sops.yaml" cfg.settings;
      in
      ''
        sopsYAML_fatal() {
          echo "FATAL: sopsYAML.nix: " "$@" >&2
          return 1
        }

        sopsYAML_main() {
          trap 'return $?' ERR

          if [[ -z "$PRJ_ROOT" ]]; then
            sopsYAML_fatal "PRJ_ROOT not set; skipping installation."
          fi

          if [[ -f "$PRJ_ROOT/.sops.yaml" ]]; then
            if [[ ! -L "$PRJ_ROOT/.sops.yaml" ]]; then
              sopsYAML_fatal "pre-existing .sops.yaml; skipping installation."
            fi
          fi

          ln -sf "${rendered}" "$PRJ_ROOT/.sops.yaml"
        }

        sopsYAML_main
      '';
  };
}
