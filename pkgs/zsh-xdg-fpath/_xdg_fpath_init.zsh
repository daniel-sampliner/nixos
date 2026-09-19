# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

zstyle ':xdg-fpath' dir "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':xdg-fpath:hash' cmd xxhsum -H3

if [[ ! -v _xdg_fpath_log_prefix ]]; then
	readonly -g _xdg_fpath_log_prefix='%N:'
fi

if [[ ! -v _xdg_fpath_extra_dirs ]]; then
	readonly -ga _xdg_fpath_extra_dirs=(site-functions vendor-completions)
fi

typeset -gaUT _XDG_FPATH_OLD_XDG_DATA_DIRS _xdg_fpath_old_xdg_data_dirs=()
typeset -gaUT _XDG_FPATH_OLD_FPATH _xdg_fpath_old_fpath=()

_xdg_fpath_xdg_to_fpath() {
	local fpath_var="${1:?}"
	shift

	local tmp_fpath=()
	local var xdg_dir fpath_dir
	for var; do
		for xdg_dir in ${(P)var}; do
			if [[ ! -d $xdg_dir ]]; then
				continue
			fi
			for fpath_dir in "$xdg_dir/zsh/${_xdg_fpath_extra_dirs[@]}"; do
				if [[ -d $fpath_dir ]]; then
					tmp_fpath+=($fpath_dir)
				fi
			done
		done
	done

	: "${(PA)fpath_var::="${tmp_fpath[@]}"}"
}

_xdg_fpath_log_info() {
	local line
	while read -r line; do
		print -P "%F{8}$1%f $line"
	done
}

_xdg_fpath_log_error() {
	local line
	while read -r line; do
		print -P "%F{1}$1%f $line"
	done
}

_xdg_fpath_compinit() {
	if ! autoload -RUz compinit 2> >(_xdg_fpath_log_error "${(%)_xdg_fpath_log_prefix}"); then
		return 1
	fi

	local dumpdir
	zstyle -s ':xdg-fpath' dir dumpdir
	if [[ ! -d "${dumpdir:?}" ]]; then
		(
			zmodload -F zsh/files b:mkdir \
				&& mkdir -m 0700 -p "$dumpdir"
		) 2> >(_xdg_fpath_log_error "${(%)_xdg_fpath_log_prefix}") \
			|| return 1
	else
		(
			old=( "$dumpdir"/*(.Nm+7) )
			(( #old )) || return 0
			zmodload -F zsh/files b:rm \
				&& rm -f -- "${old[@]}"
		) 2> >(_xdg_fpath_log_error "${(%)_xdg_fpath_log_prefix}")

	fi

	local hash hash_cmd
	zstyle -a ':xdg-fpath:hash' cmd hash_cmd
	hash=$("${hash_cmd[@]:?}" <<<"${FPATH:?}")

	local dumpfile=$dumpdir/zcompdump.xdg_fpath.${${hash%% *}:?}
	if [[ ! -s $dumpfile.zwc ]]; then
		compinit -w -d "$dumpfile" 2> >(_xdg_fpath_log_info "${(%)_xdg_fpath_log_prefix}")
		print -l "# generated with fpath:" "#   ${fpath[@]}" \
			| sed -i '1r /dev/stdin' "$dumpfile"
		zcompile -Uz "$dumpfile" 2> >(_xdg_fpath_log_info "${(%)_xdg_fpath_log_prefix}")
	else
		compinit -C -d "$dumpfile" 2> >(_xdg_fpath_log_info "${(%)_xdg_fpath_log_prefix}")
	fi

	_XDG_FPATH_OLD_FPATH="$FPATH"
}

_xdg_fpath_hook() {
	emulate -L zsh
	setopt warn_create_global rcexpandparam

	if [[ -z $_XDG_FPATH_OLD_XDG_DATA_DIRS ]]; then
		local -aU xdg_fpath=()
		_xdg_fpath_xdg_to_fpath xdg_fpath XDG_DATA_HOME xdg_data_dirs

		if [[ -n "$xdg_fpath" ]]; then
			local -aU tmp_fpath=(${(aO)fpath})
			local fpath_dir
			for fpath_dir in ${(aO)xdg_fpath}; do
				tmp_fpath+=("$fpath_dir")
			done
			fpath=(${(aO)tmp_fpath})
		fi

		_XDG_FPATH_OLD_XDG_DATA_DIRS="$XDG_DATA_DIRS"

	elif [[ $_XDG_FPATH_OLD_XDG_DATA_DIRS != "$XDG_DATA_DIRS" ]]; then
		local -a removed_xdg_data_dirs=("${_xdg_fpath_old_xdg_data_dirs[@]:|xdg_data_dirs}")
		if [[ -n "$removed_xdg_data_dirs" ]]; then
			local -a removed_xdg_fpaths=()
			_xdg_fpath_xdg_to_fpath removed_xdg_fpaths removed_xdg_data_dirs
			if [[ -n "$removed_xdg_fpaths" ]]; then
				fpath=("${fpath[@]:|removed_xdg_fpaths}")
			fi
		fi
		
		local -a added_xdg_data_dirs=("${xdg_data_dirs[@]:|_xdg_fpath_old_xdg_data_dirs}")
		if [[ -n "$added_xdg_data_dirs" ]]; then
			local -a added_xdg_fpaths=()
			_xdg_fpath_xdg_to_fpath added_xdg_fpaths added_xdg_data_dirs
			if [[ -n "$added_xdg_fpaths" ]]; then
				local -aU tmp_fpath=(${(aO)fpath})
				local fpath_dir
				for fpath_dir in ${(aO)added_xdg_fpaths}; do
					tmp_fpath+=("$fpath_dir")
				done
				fpath=(${(aO)tmp_fpath})
			fi
		fi

		_XDG_FPATH_OLD_XDG_DATA_DIRS="$XDG_DATA_DIRS"
	fi

	if [[ -z $_XDG_FPATH_OLD_FPATH ]]; then
		_xdg_fpath_compinit
	elif [[ $_XDG_FPATH_OLD_FPATH != "$FPATH" ]]; then
		_xdg_fpath_compinit
	fi
}

if ! (( ${chpwd_functions[(I)_xdg_fpath_hook]} )); then
	chpwd_functions[${precmd_functions[(I)_mise_hook]}+1,0]=_xdg_fpath_hook
fi

if ! (( ${precmd_functions[(I)_xdg_fpath_hook]} )); then
	precmd_functions[${precmd_functions[(I)_mise_hook]}+1,0]=_xdg_fpath_hook
fi

if whence -f _xdg_fpath_init >/dev/null; then
	unfunction _xdg_fpath_init
fi
