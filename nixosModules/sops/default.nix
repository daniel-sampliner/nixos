# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

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
      chpasswd = lib.mkOption {
        default = null;
        description = "File containing lines of user_name:password to be fed to {manpage}`chpasswd(8)`.";
        type = types.nullOr types.pathInStore;
      };

      importKey = lib.mkOption {
        default = null;
        type = types.nullOr types.pathInStore;
        visible = false;
      };

      keyDir = lib.mkOption {
        default = "/etc/credstore.encrypted/sops-nix/control";
        description = "Directory to contain sops age decryption key.";
        type = types.path;
      };

      secrets = lib.mkOption {
        default = { };
        description = "Attrset mapping secret names to sops-encrypted values.";
        type = types.attrsOf types.pathInStore;

        apply =
          secrets:
          pkgs.runCommand "sops-secrets" { } (
            ''
              mkdir -- "$out"
              ${lib.strings.toShellVar "secrets" secrets}
              for secret in "''${!secrets[@]}"; do
                ln -s -- "''${secrets[$secret]}" "$out/$secret"
              done
            ''
            + lib.strings.optionalString (cfg.chpasswd != null) ''
              ln -sf -- "${cfg.chpasswd}" "$out/chpasswd"
            ''
          );
      };

      socket = lib.mkOption {
        default = "/run/sops-nix.sock";
        description = "Location of sops-nix UNIX socket";
        type = types.path;
      };
    };

  config =
    let
      keyType = "ed25519";
      sshHostKey = "ssh_host_${keyType}_key";
    in
    {
      assertions = [
        {
          assertion = (cfg.chpasswd != null) -> config.services.userborn.enable;
          message = "services.userborn must be enabled to use sops.chpasswd";
        }
      ];

      services.openssh.hostKeys = lib.mkOrder 0 [
        {
          path = "/run/credentials/sshd.service/${sshHostKey}";
          type = "ed25519";
        }
      ];

      systemd.services =
        let
          mkExecline = name: text: pkgs.writers.writeExecline { } "/${name}" text + "/${name}";

          sshExtra = {
            after = [ "sops-nix-ssh-keygen.target" ];
            wants = [ "sops-nix-ssh-keygen.target" ];
            serviceConfig.LoadCredentialEncrypted = "${sshHostKey}:${cfg.keyDir}/${sshHostKey}";
          };
        in
        {
          "sops-nix@" = {
            description = "sops-nix decrypt %i";
            after = [ "sops-nix-age-key.target" ];
            requires = [ "sops-nix-age-key.target" ];

            environment = {
              SOPS_BASE_DIR = cfg.secrets.outPath;
            };

            path = [
              pkgs.age
              pkgs.sops
            ];

            serviceConfig = {
              ExecStart = lib.getExe pkgs.systemd-sops;
              LoadCredentialEncrypted = [ "age_key:${cfg.keyDir}/age_key" ];
              StandardInput = "socket";
              StandardError = "journal";

              User = "sops-nix";
              DynamicUser = true;

              CapabilityBoundingSet = [ ];

              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              PrivateDevices = true;
              PrivateIPC = true;
              PrivateNetwork = true;
              PrivateUsers = true;
              ProcSubset = "pid";
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = "tmpfs";
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectSystem = "strict";
              RestrictAddressFamilies = "none";
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
              SystemCallFilter = [ "@basic-io" ];
              UMask = "777";
            };

            unitConfig = {
              CollectMode = "inactive";
            };
          };

          sops-nix-chpasswd = lib.optionalAttrs (cfg.chpasswd != null) {
            description = "Set user passwords";
            after = [ "userborn.service" ];
            before = [ "multi-user.target" ];
            requiredBy = [ "multi-user.target" ];
            requires = [ "userborn.service" ];

            path = [ pkgs.shadow ];
            serviceConfig = {
              LoadCredential = "chpasswd:${cfg.socket}";
              ExecStart = mkExecline "sops-nix-chpasswd" ''
                importas -i CREDENTIALS_DIRECTORY CREDENTIALS_DIRECTORY
                redirfd -r 0 ''${CREDENTIALS_DIRECTORY}/chpasswd
                chpasswd
              '';
            };
          };

          sops-nix-ssh-to-age = {
            after = [ "sops-nix-ssh-key.target" ];
            before = [ "sops-nix-age-key.target" ];
            description = "Convert sops-nix SSH key to age";
            requiredBy = [ "sops-nix-age-key.target" ];
            requires = [ "sops-nix-ssh-key.target" ];

            path = [
              config.systemd.package
              pkgs.ssh-to-age
            ];
            serviceConfig = {
              ExecStart = mkExecline "sops-nix-ssh-to-age" ''
                multisubstitute {
                  importas -i CREDENTIALS_DIRECTORY CREDENTIALS_DIRECTORY
                  importas -i RUNTIME_DIRECTORY RUNTIME_DIRECTORY
                }
                cd $RUNTIME_DIRECTORY
                if { ssh-to-age -i ''${CREDENTIALS_DIRECTORY}/${sshHostKey} -o age_key -private-key }
                systemd-creds encrypt age_key ${cfg.keyDir}/age_key
              '';
              LoadCredentialEncrypted = "${sshHostKey}:${cfg.keyDir}/${sshHostKey}";
              RuntimeDirectory = "%N";
              Type = "oneshot";
            };
            unitConfig.ConditionFileNotEmpty = "!${cfg.keyDir}/age_key";
          };

          sops-nix-ssh-keygen = {
            after = [ "sshd-keygen.service" ];
            before = [ "sops-nix-ssh-key.target" ];
            requiredBy = [ "sops-nix-ssh-key.target" ];
            environment.SYSTEMD_LOG_LEVEL = "debug";
            description = "sops-nix SSH Key Generation";

            path = [
              config.programs.ssh.package
              config.systemd.package
            ];

            serviceConfig = {
              ExecStart = mkExecline "sops-nix-ssh-keygen" (
                ''
                  importas -i RUNTIME_DIRECTORY RUNTIME_DIRECTORY
                  cd $RUNTIME_DIRECTORY

                ''
                + (
                  if cfg.importKey == null then
                    ''
                      if { ssh-keygen 
                        -C ${config.networking.hostName}
                        -N "" 
                        -f ${sshHostKey}
                        -t ${keyType} }
                    ''
                  else
                    ''
                      if { install -m0400 ${cfg.importKey} ${sshHostKey} }
                      if { redirfd -w 1 ${sshHostKey}.pub ssh-keygen -y -f ${sshHostKey} }
                    ''
                )
                + ''

                  if { systemd-creds encrypt ${sshHostKey} ${cfg.keyDir}/${sshHostKey} }
                  umask 0333
                  redirfd -r 0 ${sshHostKey}.pub tee /etc/ssh/${sshHostKey}.pub
                ''
              );

              RuntimeDirectory = "%N";
              Type = "oneshot";
            };
            unitConfig.ConditionFileNotEmpty = "!${cfg.keyDir}/${sshHostKey}";
          };

          "sshd@" = sshExtra;
          sshd = sshExtra;
        };

      systemd.sockets.sops-nix = {
        description = "sops-nix credential service";
        listenStreams = [ cfg.socket ];

        socketConfig = {
          Accept = true;
          SocketMode = "0400";
        };

        wantedBy = [ "sockets.target" ];
      };

      systemd.targets.sops-nix-age-key.description = "sops-nix age key exists";
      systemd.targets.sops-nix-ssh-key.description = "sops-nix SSH key exists";

      systemd.tmpfiles.rules = [
        "d ${cfg.keyDir} 0700 - - - -"
        "d /etc/ssh 0755 - - - -"
      ];
    };
}
