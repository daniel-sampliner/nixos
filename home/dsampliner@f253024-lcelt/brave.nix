# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
let
  mkBrowserScript =
    name: dir:
    pkgs.execline.passthru.writeScript "brave-${name}" "-WS0" ''
      brave-browser --profile-directory="${dir}" $@
    '';

  combineBrowserScripts =
    drvs:
    pkgs.runCommand "brave-profile-scripts" { } ''
      ${lib.strings.toShellVar "drvs" drvs}
      for drv in "''${drvs[@]}"; do
        install -D "$drv" "$out/bin/$(stripHash "$drv")"
      done
    '';

  browser_scripts =
    lib.trivial.pipe
      {
        home = "Default";
        work = "Profile 1";
      }
      [
        (builtins.mapAttrs mkBrowserScript)
        builtins.attrValues
        combineBrowserScripts
      ];
in
{
  home.packages = [ browser_scripts ];
}
