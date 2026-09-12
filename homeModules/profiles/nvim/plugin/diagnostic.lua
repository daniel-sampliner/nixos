-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim

local should_close = false

vim.diagnostic.handlers.loclist = {
	show = function(namespace, bufnr, diagnostics, opts)
		local loclist = vim.fn.getloclist(0, { items = {}, title = {} })
		local diagnostics_title = opts.loclist.title or "Diagnostics"
		if #loclist.items >= 1 and loclist.title ~= diagnostics_title then
			return
		end

		opts.loclist.open = opts.loclist.open or false
		local winid = vim.api.nvim_get_current_win()
		vim.diagnostic.setloclist(opts.loclist)
		should_close = false
		vim.api.nvim_set_current_win(winid)
	end,
}

local augroup = vim.api.nvim_create_augroup("diagnostics", {})
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	desc = "close location list when no diagnostics",
	group = augroup,
	callback = function(ev)
		if #ev.data.diagnostics > 0 then
			return
		end

		local current_title = vim.fn.getloclist(0, { title = {} }).title
		local diagnostics_title = (vim.diagnostic.config().loclist or {}).title or "Diagnostics"

		if current_title == diagnostics_title then
			should_close = true
			vim.schedule(function()
				if should_close then
					vim.cmd.lclose()
				end
			end)
		end
	end,
})

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
