# SPDX-FileCopyrightText: 2025 Eelco Dolstra and the flake-compat contributors
#
# SPDX-License-Identifier: MIT

(import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    nodeName = lock.nodes.root.inputs.flake-compat;
  in
  fetchTarball {
    url =
      lock.nodes.${nodeName}.locked.url
        or "https://github.com/NixOS/flake-compat/archive/${lock.nodes.${nodeName}.locked.rev}.tar.gz";
    sha256 = lock.nodes.${nodeName}.locked.narHash;
  }
) { src = ./.; }).defaultNix
