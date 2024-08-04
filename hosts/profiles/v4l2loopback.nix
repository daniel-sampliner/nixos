# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, pkgs, ... }:
let
  pkg = config.boot.kernelPackages.v4l2loopback;
in
{

  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="virtual_webcam"
  '';

  boot.extraModulePackages = [ pkg ];
  environment.systemPackages = [ pkg ];

  services.udev.packages =
    let
      v4l2loopback-rules = pkgs.runCommand "v4l2loopback-rules" { } ''
        install -D -m 0644 -t "$out/lib/udev/rules.d" "${pkg.src}/udev/"*.rules
        for r in "$out/lib/udev/rules.d/"*; do
          substituteInPlace "$r" \
            --replace "/usr/bin/find " "${pkgs.findutils}/bin/find " \
            --replace "/bin/chgrp " "${pkgs.coreutils}/bin/chgrp " \
            --replace "/bin/chmod " "${pkgs.coreutils}/bin/chmod "
        done
      '';
    in
    [ v4l2loopback-rules ];
}
