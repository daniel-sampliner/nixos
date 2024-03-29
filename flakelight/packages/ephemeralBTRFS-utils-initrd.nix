# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{ ephemeralBTRFS-utils }:
ephemeralBTRFS-utils.overrideAttrs {
  buildInputs = [ ];
  nativeBuildInputs = [ ];

  dontPatchShebangs = true;

  postFixup = ''
    for b in $out/bin/*; do
      if [[ -x $b ]]; then
        sed -i '1c #!/bin/ash' "$b"
      fi
    done
  '';
}
