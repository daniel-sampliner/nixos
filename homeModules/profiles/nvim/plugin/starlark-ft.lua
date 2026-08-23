-- SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim

vim.filetype.add({
	extension = {
		ipd = "bzl",
		star = "bzl",
		starlark = "bzl",
	},
})
