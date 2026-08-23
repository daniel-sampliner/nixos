-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local vim = vim
local view

vim.keymap.set("o", "A", function()
	view = vim.fn.winsaveview()
	vim.cmd("normal! ggVG")
	vim.api.nvim_feedkeys(vim.keycode("<Plug>(RestoreView)"), "", false)
end)

vim.keymap.set("n", "<Plug>(RestoreView)", function()
	if next(view) == nil then
		return
	end

	if vim.api.nvim_buf_line_count(0) == 1 then
		return
	end

	vim.fn.winrestview(view)
end)
