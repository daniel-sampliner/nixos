#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

: "${GH_CACHE_POST_BUILD_HOOK_DIR:?}"

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

# Collect paths, dedup them, write them in batches, and cap the writers in
# flight. The batches go through nix-cache-push.sh, which stores exactly the
# given paths — nix copy would drag each path's whole closure, substitutable
# paths included, into the cache.
declare -A seen
batch=()
max_batch=16
max_in_flight=2

flush() (
	[[ $# -gt 0 ]] || return 0

	set -x
	bash "${GITHUB_WORKSPACE:?}/.github/workflows/nix-cache-push.sh" "$@"
)

# Block until an in-flight copy slot is free. A failed copy must not kill
# the daemon under set -e; report it via its job status and carry on.
reap() {
	while (($(jobs -rp | wc -l) >= max_in_flight)); do
		wait -n || :
	done
}

enqueue() {
	local out="${1:-}"
	[[ -n $out ]] || return 0
	[[ -z ${seen[$out]:-} ]] || return 0
	seen[$out]=1
	batch+=("$out")

	if ((${#batch[@]} >= max_batch)); then
		reap
		flush "${batch[@]}" &
		batch=()
	fi
}

# Read until the fifo is idle for the timeout, then flush the partial batch
# so cache population keeps up with the build instead of waiting for TERM.
read_paths() {
	local timeout="${1:?}"
	while IFS='' read -r -u "$fifo" -t "$timeout" out; do
		enqueue "$out"
	done

	if ((${#batch[@]} > 0)); then
		reap
		flush "${batch[@]}" &
		batch=()
	fi
}

while [[ $loop == loop ]]; do
	read_paths 5
done

read_paths 1

echo 'waiting for all background jobs to finish' >&2
wait || :
