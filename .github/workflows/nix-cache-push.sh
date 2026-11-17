#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Push exactly the given store paths into the local file binary cache
# ($CACHE_DIR), without their closures. `nix copy` cannot do this: its
# binary-cache uploader refuses to write a narinfo whose references do not
# already have narinfos in the destination (binary-cache-store.cc
# uploadNarInfo), so every partial path set fails and the copy drags the
# full closure along — including paths substitutable from upstream, which
# ballooned the homes cache to ~8 GiB. Substitution readers have no such
# constraint: a narinfo needs only StorePath, NarHash, URL and NarSize,
# references may point outside the cache, and a trusted cache (?trusted=1)
# accepts unsigned entries. So assemble each entry by hand from
# `nix path-info --json` and a `nix store dump-path` NAR.

set -euo pipefail

: "${CACHE_DIR:?}"

mkdir -p "$CACHE_DIR/nar"

[[ -e $CACHE_DIR/nix-cache-info ]] \
	|| printf 'StoreDir: /nix/store\n' >"$CACHE_DIR/nix-cache-info"

# nix path-info --json output shape differs by implementation: CppNix
# wraps the infos in an object keyed by store path, Lix emits an array.
# Normalize to the single info object.
read_info() {
	nix --offline path-info --json "$1" | jq -c '[ .[] ][0]'
}

push_path() {
	local out="${1:?}"

	# The narinfo is written last, so its existence implies a complete
	# entry — re-pushed paths (restored caches) are skipped, not rewritten.
	local name=${out##*/}
	local hash_part=${name:0:32}
	local narinfo="$CACHE_DIR/$hash_part.narinfo"
	[[ -e $narinfo ]] && return 0

	local info
	info=$(read_info "$out")
	out=$(jq -r '.path' <<<"$info")
	name=${out##*/}
	hash_part=${name:0:32}
	narinfo="$CACHE_DIR/$hash_part.narinfo"
	[[ -e $narinfo ]] && return 0

	local nar_size nar_hash_hex deriver ca refs
	nar_size=$(jq -r '.narSize' <<<"$info")
	# narHash arrives in SRI base64; the narinfo parser decodes the
	# prefixed hash by length, so hand it hex.
	nar_hash_hex=$(jq -r '.narHash' <<<"$info" \
		| sed 's/^sha256-//' | base64 -d | od -An -tx1 | tr -d ' \n')
	deriver=$(jq -r '.deriver // ""' <<<"$info")
	ca=$(jq -r '.ca // ""' <<<"$info")
	refs=$(jq -r '[.references[] | sub("^.*/"; "")] | join(" ")' <<<"$info")

	# The narinfo parser rejects NarSize 0; anything else missing here is
	# a metadata failure that must not surface as a garbage entry.
	[[ -n $nar_size && $nar_size != 0 && -n $nar_hash_hex && -n $out ]] || {
		echo "nix-cache-push: incomplete metadata for '$out'" >&2
		return 1
	}

	set -x

	# Store the NAR uncompressed: the actions/cache post step already
	# zstd-compresses the whole cache dir, so inner compression is pure CPU
	# on push and pure decompression on every substitution at restore. With
	# no compression the stored file is the NAR itself, so FileHash equals
	# NarHash and FileSize equals NarSize.
	local tmp_nar url
	tmp_nar=$(mktemp "$CACHE_DIR/nar/.tmp.XXXXXX")
	trap 'rm -f -- "$tmp_nar"' EXIT
	nix --offline store dump-path "$out" >"$tmp_nar"
	url="nar/$nar_hash_hex.nar"
	mv -- "$tmp_nar" "$CACHE_DIR/$url"
	trap - EXIT

	{
		echo "StorePath: $out"
		echo "URL: $url"
		echo "Compression: none"
		echo "FileHash: sha256:$nar_hash_hex"
		echo "FileSize: $nar_size"
		echo "NarHash: sha256:$nar_hash_hex"
		echo "NarSize: $nar_size"
		echo "References: $refs"
		if [[ -n $deriver ]]; then
			echo "Deriver: ${deriver##*/}"
		fi
		if [[ -n $ca ]]; then
			echo "CA: $ca"
		fi
	} >"$narinfo.tmp"
	mv -- "$narinfo.tmp" "$narinfo"
}

if [[ ${1:-} == --single ]]; then
	shift
	push_path "$1"
	exit
fi

for out in "$@"; do
	# Per-path isolation: the child shell re-arms errexit (a function
	# invoked in a || list ignores -e for its whole body, even where it is
	# explicitly set), so one failed push skips only that path. A skipped
	# entry is absent from the cache and falls back to upstream at
	# substitution time.
	[[ -n $out ]] || continue
	bash "$0" --single "$out" \
		|| echo "nix-cache-push: failed to push '$out'" >&2
done
