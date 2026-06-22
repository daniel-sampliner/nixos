#!/bin/sh

# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

redo-ifchange zsh.init
sed '/#compdef/Q' zsh.init
