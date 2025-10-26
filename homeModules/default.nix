# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, ... }:
let
  defaultNix =
    path: lib.fileset.fileFilter ({ name, type, ... }: name == "default.nix" && type == "regular") path;

  modules = lib.trivial.pipe ./profiles [
    defaultNix
    (lib.fileset.union ./default.nix)
    (lib.fileset.difference (defaultNix ./.))
    (lib.fileset.toList)
  ];
in
{
  imports = modules ++ [ ./profiles ];
}
