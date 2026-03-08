-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim
local math = math

local augroup = vim.api.nvim_create_augroup("_lsp", {})
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "register LSP autocmds",
	group = augroup,
	callback = function(ev)
		local client_id = ev.data.client_id
		local augroup = vim.api.nvim_create_augroup("lsp", {})
		vim.api.nvim_create_autocmd("BufWritePre", {
			desc = "format",
			group = augroup,
			buffer = ev.buf,
			callback = function(ev)
				vim.lsp.buf.format({ bufnr = ev.buf, async = false, id = client_id })
			end,
		})

		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			desc = "populate quickfix from diagnostics",
			group = augroup,
			buffer = ev.buf,
			callback = function(ev)
				local diagnostics = vim.diagnostic.get(ev.buf)
				vim.diagnostic.setqflist()

				local qflist = vim.fn.getqflist({ winid = 0 })
				local window = qflist.winid
				if window == nil or window == 0 then
					return
				end
				vim.api.nvim_win_set_height(window, math.min(#diagnostics, 5))
			end,
		})
	end,
})
