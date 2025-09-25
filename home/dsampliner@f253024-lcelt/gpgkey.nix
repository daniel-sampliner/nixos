# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_:
let
  gpgKey = "0x3E9DB066BFDC4A84";
in
{
  programs = {
    git.extraConfig.user.signingKey = gpgKey;
    gpg.settings.default-key = gpgKey;
    jujutsu.settings.signing.key = gpgKey;
  };
}
