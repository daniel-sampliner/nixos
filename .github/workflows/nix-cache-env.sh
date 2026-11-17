#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

CACHE_DIR="${RUNNER_TEMP:?}/nix-store-cache"
CACHE_URL="file://$CACHE_DIR?priority=0&trusted=1"
export GH_CACHE_POST_BUILD_HOOK_DIR="${RUNNER_TEMP:?}/gh-cache-post-build-hook"

{
	echo "CACHE_DIR=$CACHE_DIR"
	echo "CACHE_URL=$CACHE_URL"
	echo "GH_CACHE_POST_BUILD_HOOK_DIR=$GH_CACHE_POST_BUILD_HOOK_DIR"
} | tee -a "${GITHUB_ENV:?}"

mkdir -p "$GH_CACHE_POST_BUILD_HOOK_DIR"
