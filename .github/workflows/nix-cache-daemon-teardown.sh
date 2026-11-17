#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# This step must not fail the job, and the daemon must be drained before the
# runner saves the cache.
set +e
set -x

pid=$(<"${GH_CACHE_POST_BUILD_HOOK_DIR:?}/pid")
rm -f -- "$GH_CACHE_POST_BUILD_HOOK_DIR/fifo"
kill -TERM "$pid"
tail --follow --pid="$pid" /dev/null
