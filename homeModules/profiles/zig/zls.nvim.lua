-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local lsp_server = "zls"

-- workaround for lack of synchronous vim.lsp.buf.code_action
-- https://github.com/neovim/neovim/issues/31206
--
-- adapted from vim.lsp.buf.code_action
-- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/buf.lua
local function code_action_sync(buf, client, code_action)
	local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
	local ns_push = vim.lsp.diagnostic.get_namespace(client.id, false)
	local ns_pull = vim.lsp.diagnostic.get_namespace(client.id, true)
	local diagnostics = {}
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_pull, lnum = lnum }))
	vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_push, lnum = lnum }))

	params.context = vim.tbl_extend("force", {
		only = { code_action },
		triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
	}, {
		diagnostics = vim.tbl_map(function(d)
			return d.user_data.lsp
		end, diagnostics),
	})

	local method = "textDocument/codeAction"
	local ret = client:request_sync(method, params, 1000, buf)

	if ret.err then
		vim.notify("Failed to call method " .. method .. ": " .. vim.inspect(ret.err), vim.log.levels.ERROR)
		return
	end
	local result = ret.result

	if result == nil then
		return
	end

	for _, action in pairs(result) do
		if action.edit then
			vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
		elseif action.command then
			print("command: ", vim.inspect(action.command))
			-- client:exec_cmd(action.command)
		else
			vim.notify("Unknown action: " .. vim.inspect(action), vim.log.levels.WARN)
		end
	end
end

local augroup = vim.api.nvim_create_augroup("_" .. lsp_server, {})
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "register " .. lsp_server .. " autocmds",
	group = augroup,
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "zls" then
			return
		end

		local augroup = vim.api.nvim_create_augroup(lsp_server, {})
		local code_actions = { "source.fixAll", "source.organizeImports" }
		for _, code_action in ipairs(code_actions) do
			vim.api.nvim_create_autocmd("BufWritePre", {
				desc = code_action,
				group = augroup,
				buffer = ev.buf,
				callback = function(ev)
					code_action_sync(ev.buf, client, code_action)
				end,
			})
		end
	end,
})

vim.lsp.enable(lsp_server)
