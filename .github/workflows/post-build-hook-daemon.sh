#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

: "${GH_CACHE_POST_BUILD_HOOK_DIR:?}" "${CACHE_URL:?}"

# shellcheck disable=SC2016
envsubst '$GH_CACHE_POST_BUILD_HOOK_DIR' \
	<"${GITHUB_WORKSPACE:?}/.github/workflows/post-build-hook.sh" \
	>"$GH_CACHE_POST_BUILD_HOOK_DIR/script"
chmod a+x "$GH_CACHE_POST_BUILD_HOOK_DIR/script"

echo "$$" >"$GH_CACHE_POST_BUILD_HOOK_DIR/pid"
mkfifo "$GH_CACHE_POST_BUILD_HOOK_DIR/fifo"

exec {fifo}<>"$GH_CACHE_POST_BUILD_HOOK_DIR/fifo"

loop=loop
trap 'echo stopping loop >&2; loop=stop' INT TERM

export PATH="/nix/var/nix/profiles/default/bin:$PATH"

copy() (
	readonly out="${1:-}"
	shift

	[[ -z $out ]] && return 0

	set -x
	nix --offline copy --to "${CACHE_URL:?}" "$out"
)

while [[ $loop == loop ]]; do
	while IFS='' read -r -u "$fifo" -t 1 out; do
		copy "$out" &
	done
done

while IFS='' read -r -u "$fifo" -t 1 out; do
	copy "$out" &
done

echo 'waiting for all background jobs to finish' >&2
wait
