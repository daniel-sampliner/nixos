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
  programs.starship.settings = lib.mkMerge [
    (lib.importTOML "${cfg.package}/share/starship/presets/nerd-font-symbols.toml")

    {
      directory.truncation_symbol = "…/";
      shlvl.symbol = "";

      continuation_prompt = "\${custom.continuation}";
      custom.continuation = {
        command = ./continuation.sh;
        shell = [ "${lib.getExe pkgs.dash}" ];
        symbol = ": ";
        unsafe_no_escape = true;
        use_stdin = false;
        when = true;
      };
    }
  ];
}
