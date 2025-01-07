# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# shellcheck shell=bash

_direnv_completion_hook() {
	trap -- "" SIGINT
	trap 'trap - SIGINT' EXIT

	if ! [[ -v DEVSHELL_DIR || -v _direnv_completion__last_devshell_dir ]]; then
		return 0
	fi

	if [[ "${DEVSHELL_DIR:-}" != "${_direnv_completion__last_devshell_dir:-}" ]]; then
		if [[ -n ${_direnv_completion__last_fpath:-} ]]; then
			FPATH=${_direnv_completion__last_fpath}
		fi
		unset _direnv_completion__last_devshell_dir
		unset _direnv_completion__last_fpath

		compinit -C

		if [[ ! -v DEVSHELL_DIR ]]; then
			return 0
		fi
	fi

	if ! [[ -d $DEVSHELL_DIR/share/zsh && -v DIRENV_FILE ]]; then
		return 0
	fi

	_direnv_completion__set_if_unset _direnv_completion__last_devshell_dir "$DEVSHELL_DIR"
	_direnv_completion__set_if_unset _direnv_completion__last_fpath "$FPATH"

	local d dd changed=0
	for d in "functions" "site-functions"; do
		dd="$DEVSHELL_DIR/share/zsh/$d"
		[[ ! -d $dd ]] && continue
		[[ -n ${fpath[(r)$dd]+1} ]] && continue
		fpath=("$dd" "${fpath[@]}")
		changed=1
	done

	((!changed)) && return 0

	compinit -w -d "${DIRENV_FILE%/.envrc}/.direnv/zcompdump"
	zcompile -U "${DIRENV_FILE%/.envrc}/.direnv/zcompdump"
}

_direnv_completion__set_if_unset() {
	if [[ ! -v ${1:?} ]]; then
		printf -v "$1" '%s' "${2:?}"
	fi
}
