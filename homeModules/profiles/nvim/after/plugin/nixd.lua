-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim

vim.lsp.config("nixd", {
	settings = {
		nixd = {
			diagnostic = { suppress = { "sema-primop-removed-prefix" } },
			nixpkgs = { expr = "import <nixpkgs> { }" },
			formatting = { command = { "nixfmt" } },
		},
	},
})

vim.lsp.enable("nixd")
