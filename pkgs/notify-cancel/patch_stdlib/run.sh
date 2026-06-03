#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

readonly base_dir="${PWD:?}"

OPTIND=1
while getopts s:p:o:v opt; do
	case $opt in
	s) readonly src_dir=$OPTARG ;;
	p) readonly patch_dir=$OPTARG ;;
	o) readonly out_dir=$OPTARG ;;
	v) readonly verbose=1 ;;
	*) exit 1 ;;
	esac
done
shift "$((OPTIND - 1))"

: "${src_dir:?}" "${patch_dir:?}" "${out_dir:?}"

if [[ ${verbose:-} == 1 ]]; then
	declare -p src_dir patch_dir out_dir >&2
	set -x
fi

cp --recursive --no-preserve=mode "$src_dir/." "$out_dir/lib"
cd "$out_dir"

git init
git config user.name 'zigbuild'
git config user.email '<>'
git add .
git commit -m init
git am "$base_dir/$patch_dir"/*.patch
