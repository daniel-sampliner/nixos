# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.starship;
in
{
  programs.starship.settings =
    lib.attrsets.recursiveUpdate
      (lib.importTOML "${cfg.package}/share/starship/presets/nerd-font-symbols.toml")
      {
        aws.symbol = " ";
        custom.continuation.symbol = ": ";
        directory.truncation_symbol = "…/";
        directory.read_only = " 󰌾 ";
        gcloud.symbol = " ";
        shlvl.symbol = "";
      };
}
