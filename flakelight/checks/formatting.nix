# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pkgs:
let
  inherit (pkgs)
    lib
    outputs'
    src
    diffutils
    ;
in
lib.mkForce ''
  if ! ${lib.getExe outputs'.formatter} --ci .; then
    ${lib.getExe' diffutils "diff"} -qr ${src} . \
      | sed 's/Files .* and \(.*\) differ/File \1 not formatted/g'
  fi
''
