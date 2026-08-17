-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim
local math = math

local augroup = vim.api.nvim_create_augroup("lsp", {})
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "register LSP autocmds",
	group = augroup,
	callback = function(ev)
		local client_id = ev.data.client_id
		local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
		local client_augroup = vim.api.nvim_create_augroup("lsp_" .. client.name, {})

		if
			not client:supports_method("textDocument/willSaveWaitUntil")
			and client:supports_method("textDocument/formatting")
		then
			vim.api.nvim_create_autocmd("BufWritePre", {
				desc = "format",
				group = client_augroup,
				buffer = ev.buf,
				callback = function(ev)
					vim.lsp.buf.format({ bufnr = ev.buf, async = false, id = client_id })
				end,
			})
		end

		vim.opt.updatetime = 2000
		local common_augroup = vim.api.nvim_create_augroup("lsp_common", {})
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			desc = "populate quickfix from diagnostics",
			group = common_augroup,
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

		vim.api.nvim_create_autocmd({ "CursorHold" }, {
			desc = "populate quickfix from diagnostics",
			group = common_augroup,
			buffer = ev.buf,
			callback = function(ev)
				local diagnostics = vim.diagnostic.get(ev.buf)
				vim.diagnostic.setqflist({ open = false })

				local qflist = vim.fn.getqflist({ winid = 0 })
				local window = qflist.winid
				if window == nil or window == 0 then
					return
				end
				vim.api.nvim_win_set_height(window, math.min(#diagnostics, 5))
			end,
		})

		vim.api.nvim_create_autocmd({ "CursorHold" }, {
			desc = "populate quickfix from diagnostics",
			group = common_augroup,
			buffer = ev.buf,
			callback = function(ev)
				vim.diagnostic.open_float({
					bufnr = ev.buf,
					scope = "cursor",
				})
			end,
		})
	end,
})
