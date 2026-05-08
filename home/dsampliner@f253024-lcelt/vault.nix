# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  pkgs,
  ...
}:

{
  home.packages =
    let
      inherit (pkgs) openbao;
      vault-shim = pkgs.runCommand "vault-shim" {} ''
        mkdir -p "$out/bin"
        ln -s "${lib.getExe openbao}" "$out/bin/vault"
      '';
    in
    builtins.attrValues {
      inherit openbao vault-shim;
    };
}
