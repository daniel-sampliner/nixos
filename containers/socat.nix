# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  dockerTools,
  nix2container,

  curl,
  socat,
}:
nix2container.buildImage {
  name = socat.pname;
  tag = socat.version;

  copyToRoot = [
    curl
    dockerTools.caCertificates
    socat
  ];

  config.Entrypoint = [ "socat" ];
}
