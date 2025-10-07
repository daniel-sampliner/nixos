-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local strings = require("strings")

local log = require("log")
local nix = require("nix")

local keep_vars = {}
for _, v in ipairs({
	"IN_NIX_SHELL",
	"name",
	"PKG_CONFIG_PATH",
	"PYTHONPATH",
	"XDG_DATA_DIRS",
}) do
	keep_vars[v] = true
end

local pathlike_vars = {
	["PKG_CONFIG_PATH"] = true,
	["PYTHONPATH"] = true,
	["XDG_CONFIG_DIRS"] = true,
	["XDG_DATA_DIRS"] = true,
}

function PLUGIN:MiseEnv(ctx)
	if not ctx.options.enable then
		return {}
	end

	local env = nix.dev_env(ctx.options)
	if not env then
		return {}
	end

	local val
	local ret = {}
	for key, value in pairs(env) do
		if keep_vars[key] then
			if pathlike_vars[key] then
				val = os.getenv(key)
				if val and not strings.has_prefix(val, value) then
					value = strings.join({ value, val }, ":")
				end
			end
			log.debug(key .. "=" .. value)
			ret[#ret + 1] = { key = key, value = value }
		end
	end

	return ret
end
