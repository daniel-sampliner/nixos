-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim

vim.diagnostic.config({
	jump = {
		on_jump = function(diagnostic, bufnr)
			if not diagnostic then
				return
			end

			vim.diagnostic.show(
				diagnostic.namespace,
				bufnr,
				{ diagnostic },
				{ virtual_lines = { current_line = true }, virtual_text = { current_line = false } }
			)
		end,
	},

	loclist = {
		open = true,
		severity = { min = vim.diagnostic.severity.WARN },
	},

	severity_sort = true,
	virtual_text = { current_line = nil },
})
