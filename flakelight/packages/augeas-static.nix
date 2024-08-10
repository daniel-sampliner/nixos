# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pkgsStatic }: pkgsStatic.augeas.overrideAttrs { doCheck = false; }
