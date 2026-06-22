#!/bin/sh

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

switcher init "$2" \
	| sed \
		-e "s/switch(/${COMMAND_NAME:-kswitch}(/" \
		-e 's/has_prefix[( ]/__kswitch_\0/'
