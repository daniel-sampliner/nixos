# SPDX-FileCopyrightText: 2024-2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  caddy,
  curlMinimal,
  dockerTools,
  lib,
  mailcap,
  nix2container,
}:
let
  name = caddy.pname;

  caddy-w-plugins =
    (caddy.withPlugins {
      plugins = [ "github.com/tailscale/caddy-tailscale@latest" ];
      hash = "sha256-I9A+/rwj97qu2yAP3rm+4+QBJjOKzngMM14nWZ3r6Q4=";
    }).overrideAttrs
      (
        _: prev: {
          patchPhase = prev.patchPhase or "" + ''
            go mod edit -go="${caddy.go.version}"
          '';

          installCheckPhase =
            lib.strings.replaceString ''[[ "''${modules[$mod]}" != "$ver" ]]''
              ''[[ "$ver" != latest && "''${modules[$mod]}" != "$ver" ]]''
              prev.installCheckPhase;
        }
      );
in
nix2container.buildImage {
  inherit name;
  tag = caddy.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        caddy-w-plugins
        curlMinimal
      ];
      pathsToLink = [ "/bin" ];
    })
    (buildEnv {
      name = "etc";
      paths = [
        dockerTools.caCertificates
        mailcap
      ];
      pathsToLink = [ "/etc" ];
    })
  ];

  config = {
    Entrypoint = [ "caddy" ];
    Cmd = [
      "run"
      "--config"
      "/etc/caddy/Caddyfile"
      "--adapter"
      "caddyfile"
    ];

    Env = [
      "CADDY_VERSION=${caddy-w-plugins.version}"
      "XDG_CONFIG_HOME=/opt/caddy/config"
      "XDG_DATA_HOME=/opt/caddy/data"
    ];
    ExposedPorts = {
      "80/tcp" = { };
      "443/tcp" = { };
      "443/udp" = { };
      "2019/tcp" = { };
    };
    WorkingDir = "/srv";
  };
}
// {
  passthru = { inherit caddy-w-plugins; };
}
