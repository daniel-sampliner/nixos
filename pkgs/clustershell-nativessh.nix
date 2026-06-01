# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  openssh,
  python3Packages,
}:
python3Packages.clustershell.overrideAttrs (prev: {
  postPatch =
    builtins.replaceStrings [ "${openssh}/bin/ssh" "${openssh}/bin/scp" ] [ "ssh" "scp" ]
      prev.postPatch;
})
