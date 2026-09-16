-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim
vim.lsp.enable("gopls")
vim.lsp.config("gopls", {
	cmd = { "gopls", "-remote=auto" },
	settings = { gopls = {
		gofumpt = true,
	} },
})
