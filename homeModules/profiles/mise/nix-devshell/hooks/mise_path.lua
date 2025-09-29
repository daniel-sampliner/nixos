-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local strings = require("strings")

local log = require("log")
local nix = require("nix")

function PLUGIN:MisePath(ctx)
	if not ctx.options.enable then
		return {}
	end

	local env = nix.dev_env(ctx.options)
	local path = env["PATH"]
	if not path then
		return {}
	end

	log.debug("PATH=" .. path)
	return strings.split(path, ":")
end
