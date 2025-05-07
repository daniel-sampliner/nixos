# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, emptyFile }:
pkg: emptyFile.overrideAttrs { name = "${lib.getName pkg}-${lib.getVersion pkg}"; }
