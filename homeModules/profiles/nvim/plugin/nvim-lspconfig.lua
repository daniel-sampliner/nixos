-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim

local augroup = vim.api.nvim_create_augroup("lsp", {})
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "register LSP autocmds",
	group = augroup,
	callback = function(ev)
		local client_id = ev.data.client_id
		local client = assert(vim.lsp.get_client_by_id(client_id))
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
	end,
})
