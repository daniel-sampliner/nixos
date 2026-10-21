# SPDX-FileCopyrightText: 2024, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  catatonit,
  nix2container,
}:
nix2container.buildImage {
  name = "pause";
  tag = "0.0.1";

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [ catatonit ];
      pathsToLink = [ "/bin" ];
    })
  ];

  config = {
    Entrypoint = [
      "catatonit"
      "-P"
    ];
    User = "65534";
  };
}
