# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# shellcheck shell=sh

if test "$STARSHIP_CONTINUATION" != true; then
	exit 0
fi

case $STARSHIP_SHELL in
zsh) exec zsh -fdc 'printf '\''%s'\'' '\''%_'\''' ;;
bash) printf '%s' '∙' ;;
esac
