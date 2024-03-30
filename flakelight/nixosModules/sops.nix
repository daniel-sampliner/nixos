# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sops;
in
{
  options.sops =
    let
      inherit (lib) types;
    in
    {
      key = lib.mkOption {
        default = "";
        description = "sops decryption key.";
        type = types.path;
        visible = false;
      };

      userPasswords = lib.mkOption {
        default = { };
        description = "Attrset mapping users to sops-encrypted files containing their hashed password.";
        type = types.attrsOf types.path;
      };
    };

  config =
    let
      smbiosKey = "io.systemd.credential.binary:sops.key";
      sopsMountpoint = "/run/sops-secrets";

      sshHostKey = lib.pipe config.services.openssh.hostKeys [
        (lib.findFirst (k: k.type == "ed25519") { })
        (lib.attrByPath [ "path" ] "")
      ];
    in
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = lib.isStringLike sshHostKey && builtins.substring 0 1 (toString sshHostKey) == "/";
            message = "No usable ed25519 SSH host key for decryption";
          }
        ];

        sops.key = sshHostKey;
      }

      (lib.mkIf (cfg.userPasswords != { }) {
        boot.specialFileSystems.${sopsMountpoint} = {
          fsType = "ramfs";
          options = [
            "nosuid"
            "nodev"
            "mode=750"
            "size=1k"
          ];
        };

        system.activationScripts = {
          sopsUserPasswords = {
            deps = [ "specialfs" ];
            supportsDryActivation = true;
            text =
              ''
                (
                set -e
                if [[ $NIXOS_ACTION == dry-activate ]]; then
                  export PS4="+[''${BASH_SOURCE[0]##*/}:$LINENO] "
                  set -x
                  readonly dry=1
                fi

                if [[ ! -e "${sshHostKey}" ]]; then
                  ''${dry:+:} ${lib.getExe' pkgs.dmidecode "dmidecode"} -t 11 \
                    | while read -r line; do
                      if [[ $line != *${smbiosKey}=* ]]; then
                        continue
                      fi
                      ''${dry:+:} mkdir -p "${builtins.dirOf sshHostKey}"
                      ''${dry:+:} base64 -d <<<"''${line#*${smbiosKey}=}" >"${sshHostKey}"
                      break
                    done
                fi

                export SOPS_AGE_KEY_FILE=${sopsMountpoint}/age
                ''${dry:+:} ${lib.getExe pkgs.ssh-to-age} \
                  -i "${sshHostKey}" \
                  -o "$SOPS_AGE_KEY_FILE" \
                  -private-key

              ''
              + (lib.pipe cfg.userPasswords [
                (lib.mapAttrsToList (
                  user: encrypted: ''
                    ''${dry:+:} ${lib.getExe pkgs.sops} \
                      --decrypt \
                      --output "${sopsMountpoint}/${user}.passwd" \
                      "${encrypted}"
                  ''
                ))
                lib.concatLines
              ])
              + ''
                )
              '';
          };

          unmountSops = {
            deps = [
              "sopsUserPasswords"
              "users"
            ];
            supportsDryActivation = true;
            text = ''
              (
              set -e
              if [[ $NIXOS_ACTION == dry-activate ]]; then
                export PS4="+[''${BASH_SOURCE[0]##*/}:$LINENO] "
                readonly dry=1
                set -x
              fi
              ''${dry:+:} umount "${sopsMountpoint}"
              )
            '';
          };

          users.deps = [ "sopsUserPasswords" ];
        };

        users.users = builtins.mapAttrs (n: _: {
          hashedPasswordFile = "${sopsMountpoint}/${n}.passwd";
        }) cfg.userPasswords;
      })
    ];
}
