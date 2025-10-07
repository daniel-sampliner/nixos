-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local strings = require("strings")

local M = {}

local ansi = {
	ESC = "\027",
	dim = "[2m",
	bright = "[1m",
	reset = "[0m",
}

function M.debug(msg)
	local verbose = os.getenv("MISE_VERBOSE")
	if verbose and string.len(verbose) > 0 then
		io.stderr:write(
			strings.join(
				{ ansi.ESC, ansi.bright, "mise-nix-devshell ", ansi.ESC, ansi.reset, msg, "\n" },
				""
			)
		)
	end
end

function M.info(msg)
	io.stderr:write(strings.join({ ansi.ESC, ansi.dim, "mise-nix-devshell ", ansi.ESC, ansi.reset, msg, "\n" }, ""))
end

function M.error(msg)
	io.stderr:write(
		strings.join({ ansi.ESC, ansi.bright, "mise-nix-devshell ", ansi.ESC, ansi.reset, msg, "\n" }, "")
	)
end

return M
