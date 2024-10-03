# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  dockerTools,
  lib,
  nix2container,
  noopPkg,
  replaceDependencies,
  writeText,
  writers,

  coreutils,
  curl-healthchecker,
  qbittorrent-nox,

  # unneeded dependencies
  at-spi2-core,
  cairo,
  cups,
  dbus,
  dconf,
  fontconfig,
  freetype,
  gdk-pixbuf,
  gsettings-desktop-schemas,
  gtk3,
  harfbuzz,
  libdrm,
  libglvnd,
  libinput,
  librsvg,
  libxkbcommon,
  mariadb-connector-c,
  mtdev,
  pango,
  postgresql,

  qt6,
  xorg,
}:
let
  unneeded =
    builtins.map lib.getLib [
      at-spi2-core
      cairo
      cups
      dbus
      dconf
      fontconfig
      freetype
      gdk-pixbuf
      gsettings-desktop-schemas
      gtk3
      harfbuzz
      libdrm
      libglvnd
      libinput
      librsvg
      libxkbcommon
      mariadb-connector-c
      mtdev
      pango
      postgresql

      qt6.qtdeclarative
      qt6.qtsvg
      qt6.qttranslations

      xorg.libICE
      xorg.libSM
      xorg.libX11
      xorg.libxcb
      xorg.xcbutilcursor
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.xcbutilwm
    ]
    ++ [ dbus.dev ];

  replacements = builtins.map (pkg: {
    oldDependency = pkg;
    newDependency = noopPkg pkg;
  }) unneeded;

  qbt = replaceDependencies {
    inherit replacements;

    drv = qbittorrent-nox;
  };

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
    define -s curl "curl -qsSf --max-time 1 --retry 10 --retry-max-time 15"

    $curl localhost:8080/api/v2/app/version
  '';
in
nix2container.buildImage {
  name = qbittorrent-nox.pname;
  tag = qbittorrent-nox.version;

  layers = lib.singleton (
    nix2container.buildLayer { deps = builtins.map (builtins.getAttr "newDependency") replacements; }
  );

  copyToRoot = [
    dockerTools.caCertificates

    (buildEnv {
      name = "root";
      paths = [
        coreutils
        curl-healthchecker
        entrypoint
        healthcheck
        qbt
      ];
      pathsToLink = [ "/bin" ];
    })
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
// {
  passthru = {
    inherit qbt;
  };
}
