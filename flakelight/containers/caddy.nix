# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  buildGoModule,
  dockerTools,
  lib,
  nix2container,
  runCommandLocal,
  writeText,

  caddy,
  mailcap,
}:
let
  name = caddy.pname;

  caddy-w-plugins =
    let
      modules = [ "github.com/tailscale/caddy-tailscale" ];
      modulesFile = writeText "modules" (lib.concatMapStrings (m: "_ \"${m}\"\n") modules);
      src = runCommandLocal "src-patched" { } ''
        cp -a ${caddy.src} $out
        chmod -R u+w $out
        sed -i -E \
          '\:^[[:blank:]]+// plug in Caddy modules here$:r ${modulesFile}' \
          $out/cmd/caddy/main.go
        ${caddy.go}/bin/gofmt -w $out/cmd/caddy/main.go
      '';
    in
    caddy.override {
      buildGoModule =
        args:
        buildGoModule (
          args
          // {
            inherit src;
            overrideModAttrs = old: {
              preBuild =
                old.preBuild or ""
                + ''
                  go get ${lib.escapeShellArgs modules}
                  go mod tidy
                '';

              postInstall =
                old.postInstall or ""
                + ''
                  install -Dm0644 -t "$out/smuggle" go.mod go.sum
                '';
            };
            postConfigure =
              caddy.postConfigure or ""
              + ''
                cp vendor/smuggle/go.{mod,sum} .
              '';
            vendorHash = "sha256-Xz2yf3PgqJiSaJ5KTJhtCQIEv6+W/spMXvvrjVfLQMQ=";
          }
        );
    };
in
nix2container.buildImage {
  inherit name;
  tag = caddy.version;

  copyToRoot = buildEnv {
    name = "root";
    paths = [
      caddy-w-plugins
      dockerTools.caCertificates
      mailcap
    ];
  };

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
