# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    nodeName = lock.nodes.root.inputs.flake-compat;
    node = lock.nodes.${nodeName}.locked;
  in
  builtins.fetchTarball {
    url = node.url or "https://github.com/nix-community/flake-compat/archive/${node.rev}.tar.gz";
    sha256 = node.narHash;
  }
) { src = ./.; }
