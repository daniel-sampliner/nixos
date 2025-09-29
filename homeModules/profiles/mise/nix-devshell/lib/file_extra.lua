-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local M = {}

function M.dirname(f)
	ret = f:match("(.*/)")
	if not ret then
		return "."
	end
	return ret
end

function M.exists(f)
	local handle = io.open(f, "r")

	if not handle then
		return false
	end

	handle:close()
	return true
end

return M
