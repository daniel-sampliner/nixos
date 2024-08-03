# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  buildEnv,
  nix2container,

  catatonit,
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
