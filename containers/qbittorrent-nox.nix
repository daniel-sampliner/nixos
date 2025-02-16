# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  nix2container,
  writeText,
  writers,

  coreutils,
  curl-healthchecker,
  qbittorrent-nox,
}:
let
  config = writeText "qBittorrent.conf" ''
    [LegalNotice]
    Accepted=true
  '';

  entrypoint = writers.writeExecline { flags = "-WS0"; } "/bin/entrypoint" ''
    multisubstitute {
      importas -D deny QBT_LEGAL_NOTICE QBT_LEGAL_NOTICE
      importas -i XDG_CACHE_HOME XDG_CACHE_HOME
      importas -i XDG_CONFIG_HOME XDG_CONFIG_HOME
      importas -i XDG_DATA_HOME XDG_DATA_HOME
    }
    multisubstitute {
      define confDir ''${XDG_CONFIG_HOME}/qBittorrent
      define logDir ''${XDG_DATA_HOME}/qBittorrent/logs
      define log ''${XDG_DATA_HOME}/qBittorrent/logs/qbittorrent.log
    }

    foreground { echo QBT_LEGAL_NOTICE: $QBT_LEGAL_NOTICE }
    if {
      case -i -N $QBT_LEGAL_NOTICE {
        "confirm" {
          if { mkdir -p $confDir }
          cp
            --backup=numbered --update --no-preserve=all --verbose
            ${config} ''${confDir}/qBittorrent.conf
        }
      }
      foreground {
        fdmove -c 1 2
        echo "set QBT_LEGAL_NOTICE to \"confirm\" to accept legal notice"
      }
      exit 1
    }

    execline-umask 0022

    if { mkdir -p $logDir }
    ifelse
      { eltest -f $log }
      {
        foreground { fdmove -c 1 2 echo "log $log exists! move it first!" }
        exit 1
      }
    if { ln -sfv /proc/self/fd/2 $log }

    emptyenv -c
    stdbuf -oL qbittorrent-nox $@
  '';

  healthcheck = writers.writeExecline { } "/bin/healthcheck" ''
    curl -qsSf
      --max-time 1
      --retry 10
      --retry-max-time 15
      localhost:8080/api/v2/app/version
  '';
in
nix2container.buildImage {
  name = qbittorrent-nox.pname;
  tag = qbittorrent-nox.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        coreutils
        curl-healthchecker
        entrypoint
        healthcheck
        qbittorrent-nox
      ];
      pathsToLink = [ "/bin" ];
    })

    dockerTools.caCertificates
  ];

  config = {
    Entrypoint = [ "entrypoint" ];
    Env = [
      "QBT_LEGAL_NOTICE=deny"
      "XDG_CACHE_HOME=/var/cache"
      "XDG_CONFIG_HOME=/etc"
      "XDG_DATA_HOME=/var/lib"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
    Volumes = {
      "/etc" = { };
      "/var/cache" = { };
      "/var/lib" = { };
    };
  };
}
