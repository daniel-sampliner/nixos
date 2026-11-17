#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

# cachix use replaces substituters in the user config; re-add the file cache
# dropped from the system config.
echo "extra-substituters = ${CACHE_URL:?}" | tee -a ~/.config/nix/nix.conf
