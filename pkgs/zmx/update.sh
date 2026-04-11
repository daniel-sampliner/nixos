#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME:+${FUNCNAME}(): }'
set -eu

readonly git_url="${1:?}"

version=$(list-git-tags --url="$git_url" \
	| grep '^v' \
	| sort --version-sort \
	| tail --lines=1)
version=${version#v}
readonly version

changes=$(update-source-version --print-changes "${UPDATE_NIX_PNAME:?}" "${version:?}")
readonly changes

if ! jq --exit-status 'length > 0' <<<"${changes:?}"; then
	echo "$changes"
	exit 0
fi

raw_url=${git_url/github.com/raw.githubusercontent.com}
raw_url=${raw_url%.git}
readonly raw_url

zon_nix=$PWD/pkgs/zmx/build.zig.zon.nix
zig2nix zon2nix \
	<(wget -O - "$raw_url/refs/tags/v$version/build.zig.zon2json-lock") - \
	| nixfmt >"$zon_nix"

jq \
	--compact-output \
	--arg zon_nix "$zon_nix" \
	'.[0] |= (.files |= . + [$zon_nix])' \
	<<<"${changes:?}"
