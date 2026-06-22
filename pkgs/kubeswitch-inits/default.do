#!/bin/sh

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

readonly prefix="${1%.*}"
readonly suffix="${1##*.}"

case $prefix in
init | completion)
	redo-ifchange "$suffix.$prefix"
	cat "$suffix.$prefix"
	;;
*)
	echo "unknown target $1" >&2
	exit 1
	;;
esac
