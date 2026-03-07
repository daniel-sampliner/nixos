-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

vim.lsp.config["zls"] = {
	cmd = { "zls" },
	filetypes = { "zig" },
	root_markers = { "build.zig" },
}

local augroup = vim.api.nvim_create_augroup("zls", {})
vim.api.nvim_create_autocmd("FileType", {
	desc = "register zig autocmds",
	group = augroup,
	pattern = { "zig" },
	callback = function(ev)
		local augroup_local = vim.api.nvim_create_augroup("zls_local", {})

		vim.api.nvim_create_autocmd("BufWritePre", {
			desc = "LSP",
			group = augroup_local,
			buffer = ev.buf,
			callback = function(evv)
				vim.lsp.buf.code_action({ context = { only = { "source.fixAll" } }, apply = true })

				vim.lsp.buf.code_action({
					context = { only = { "source.organizeImports" } },
					apply = true,
				})

				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
})

vim.lsp.enable("zls")
