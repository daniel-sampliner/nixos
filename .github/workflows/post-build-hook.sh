#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

[[ ! -p "$GH_CACHE_POST_BUILD_HOOK_DIR/fifo" ]] && exit 0

read -r -a out_paths <<<"${OUT_PATHS:-}"

for out_path in "${out_paths[@]}"; do
	# shellcheck disable=SC2016
	timeout 5 sh -c 'echo "$1" >>"$2"' _ "$out_path" "$GH_CACHE_POST_BUILD_HOOK_DIR/fifo"
done
