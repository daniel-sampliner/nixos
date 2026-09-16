-- SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local os = os
local vim = vim

local dir = vim.fs.dirname(debug.getinfo(1, "S").source:gsub("^@", ""))
local flake_expr = string.format("builtins.getFlake (toString %s)", dir)

local user = os.getenv("USER")
local hostname = vim.fn.hostname()

vim.lsp.config("nixd", {
	settings = {
		nixd = {
			nixpkgs = { expr = string.format("import (%s).inputs.nixpkgs { }", flake_expr) },

			options = {
				flake_parts = {
					expr = string.format(
						"let flake = %s; in flake.debug.options // flake.currentSystem.options",
						flake_expr
					),
				},

				home_manager = {
					expr = string.format(
						[[(%s).homeConfigurations."%s@%s".options]],
						flake_expr,
						user,
						hostname
					),
				},
			},
		},
	},
})
