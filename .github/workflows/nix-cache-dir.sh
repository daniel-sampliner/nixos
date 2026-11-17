#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

mkdir -p "${CACHE_DIR:?}"/{nar,narinfo,build-trace-v2,log}
sudo chown -Rc "${USER:?}" "${CACHE_DIR:?}"
