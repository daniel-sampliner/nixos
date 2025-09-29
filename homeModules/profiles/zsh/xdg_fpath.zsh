# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_xdg_fpath_xdg_to_fpath() {
	local fpath_var="${1:?}"
	shift

	local tmp_fpath=()
	local extra_dirs=(site-functions vendor-functions vendor-completions)
	local xdg_dir fpath_dir
	for xdg_dir in "${xdg_data_dirs[@]}"; do
		for fpath_dir in "$xdg_dir/zsh/${extra_dirs[@]}"; do
			if [[ -d $fpath_dir ]]; then
				tmp_fpath+=("$fpath_dir")
			fi
		done
	done

	: "${(PA)fpath_var::="${tmp_fpath[@]}"}"
}

readonly _xdg_fpath_log_prefix='%N:'

_xdg_fpath_log_info() {
	local line
	while read -r line; do
		print -P "%F{8}$1%f $line"
	done
}

_xdg_fpath_compinit() {
	local hash
	hash=$(xxhsum -H3 <<<"${FPATH:?}")
	
	local dumpfile=${XDG_RUNTIME_DIR:?}/zsh/zcompdump.xdg_fpath.${${hash%% *}:?}
	if autoload -RUz compinit; then
		if [[ ! -s $dumpfile.zwc ]]; then
			compinit -w -d "$dumpfile" 2> >(_xdg_fpath_log_info "${(%)_xdg_fpath_log_prefix}")
			print -l "# generated with fpath:" "#   ${fpath[@]}" \
				| sed -i '1r /dev/stdin' "$dumpfile"
			zcompile -Uz "$dumpfile" 2> >(_xdg_fpath_log_info "${(%)_xdg_fpath_log_prefix}")
		else
			compinit -C -d "$dumpfile" 2> >(_xdg_fpath_log_info "${(%)_xdg_fpath_log_prefix}")
		fi
	fi
}

_xdg_fpath_hook() {
	emulate -L zsh
	setopt warn_create_global rcexpandparam

	typeset -gaUT _XDG_FPATH_OLD_XDG_DATA_DIRS _xdg_fpath_old_xdg_data_dirs=()
	typeset -gaUT _XDG_FPATH_OLD_XDG_FPATH _xdg_fpath_old_xdg_fpath=()
	typeset -gaUT _XDG_FPATH_OLD_FPATH _xdg_fpath_old_fpath=()

	if [[ -z $_XDG_FPATH_OLD_XDG_DATA_DIRS ]]; then
		_xdg_fpath_xdg_to_fpath _xdg_fpath_old_xdg_fpath

		local fpath_changed=0
		local -aU tmp_fpath=(${(aO)fpath})
		local fpath_dir
		for fpath_dir in ${(aO)_xdg_fpath_old_xdg_fpath}; do
			fpath_changed=1
			tmp_fpath+=("$fpath_dir")
		done
		readonly fpath_changed
		fpath=(${(aO)tmp_fpath})

	elif [[ $_XDG_FPATH_OLD_XDG_DATA_DIRS != "$XDG_DATA_DIRS" ]]; then
		local -aU new_fpath=()
		_xdg_fpath_xdg_to_fpath new_fpath

		if [[ $_xdg_fpath_old_xdg_fpath == "$new_fpath" ]]; then :
		else
			local -aU tmp_fpath=(${(aO)fpath})
			local remove_dir add_dir idx
			for remove_dir in "${_xdg_fpath_old_xdg_fpath[@]:|new_fpath}"; do
				tmp_fpath[$tmp_fpath[(i)"$remove_dir"]]=()
			done
			for add_dir in "${new_fpath[@]:|_xdg_fpath_old_xdg_fpath}"; do
				tmp_fpath+=("$add_dir")
			done
			fpath=(${(aO)tmp_fpath})
		fi
	fi
	_xdg_fpath_old_xdg_data_dirs=("${xdg_data_dirs[@]}")

	if [[ -z $_XDG_FPATH_OLD_FPATH ]] && ((fpath_changed)); then
		_xdg_fpath_compinit
	elif [[ $_XDG_FPATH_OLD_FPATH != $FPATH ]]; then
		_xdg_fpath_compinit
	fi
	_xdg_fpath_old_fpath=("${fpath[@]}")
}

if ! (( ${chpwd_functions[(I)_xdg_fpath_hook]} )); then
	chpwd_functions[${precmd_functions[(I)_mise_hook]}+1,0]=_xdg_fpath_hook
fi

if ! (( ${precmd_functions[(I)_xdg_fpath_hook]} )); then
	precmd_functions[${precmd_functions[(I)_mise_hook]}+1,0]=_xdg_fpath_hook
fi

# typeset -f -T _xdg_fpath_xdg_to_fpath _xdg_fpath_compinit _xdg_fpath_hook

# autoload -RUz add-zsh-hook
# add-zsh-hook -Uz chpwd _xdg_fpath_hook
# add-zsh-hook -Uz precmd _xdg_fpath_hook
