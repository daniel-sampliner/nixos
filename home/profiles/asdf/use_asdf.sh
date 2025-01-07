# SPDX-FileCopyrightText: 2022 Victor Hugo Borja <vborja@apache.org>
#
# SPDX-License-Identifier: Apache-2.0

# shellcheck shell=bash

# Taken from asdf-direnv plugin:
# https://github.com/asdf-community/asdf-direnv/blob/a2219c293d8cdaa2b7e5f38a63788334b481e00d/lib/setup-lib.bash#L184
use_asdf() {
	source_env "$(asdf direnv envrc "$@")"
}
