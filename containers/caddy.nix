# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
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
  curl-healthchecker,
  mailcap,
}:
let
  name = caddy.pname;

  caddy-w-plugins =
    let
      modules = [
        {
          name = "github.com/tailscale/caddy-tailscale";
        }
      ];
      modulesFile = writeText "modules" (
        lib.concatMapStrings (m: "_ \"${m}\"\n") (builtins.map (m: m.name) modules)
      );
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
                  cp go.mod go.mod.old
                  cp go.sum go.sum.old
                  go get ${
                    lib.escapeShellArgs (
                      builtins.map (m: m.name + lib.optionalString (m ? version) "@${m.version}") modules
                    )
                  }
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
            vendorHash = "sha256-9TKZo3vp62a9G7ibg2tAO0Qh9rrW/SnrkgX+wXbNWPE=";
          }
        );
    };
in
nix2container.buildImage {
  inherit name;
  tag = caddy.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        caddy-w-plugins
        curl-healthchecker
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
