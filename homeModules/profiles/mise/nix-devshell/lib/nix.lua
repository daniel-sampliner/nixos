-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local cmd = require("cmd")
local file = require("file")
local json = require("json")
local strings = require("strings")

local log = require("log")

local M = {}

function M.get_base_dir()
	local mise_config = json.decode(cmd.exec("mise config ls --json"))[1].path
	local mise_dir = mise_config:match("(.*/)")
	if string.len(mise_dir) < 1 then
		error("could not locate mise base dir")
		return nil
	end

	return mise_dir
end

function M.get_hash(options, base_dir)
	local files = options.watch_files or { "flake.lock", "flake.nix" }
	local hash_cmd = options.hash_cmd or "xxhsum -H3"

	if not files or next(files) == nil then
		return nil
	end

	local output = cmd.exec(
		strings.join({
			"<<<",
			base_dir,
			"cat -",
			strings.join(files, " "),
			"|",
			hash_cmd,
		}, " "),
		{ cwd = base_dir }
	)
	local hash = strings.split(output, " ")[1]
	return hash
end

function M.dev_env(options)
	local needs_update = true
	local base_dir = M.get_base_dir()
	local cache_dir = file.join_path(base_dir, ".mise-nix-devshell")
	local profile = file.join_path(cache_dir, "dev-env")
	local cached_hash = file.join_path(cache_dir, "hash")

	local hash = M.get_hash(options, base_dir)
	local profile_f = io.open(profile, "r")
	if profile_f then
		log.debug("profile exists")
		cmd.exec("nix profile wipe-history --quiet --profile " .. profile)
		hash_f = io.open(cached_hash, "r")
		if hash_f then
			log.debug("previous hash exists")
			prev_hash = hash_f:read("*l")
			if hash and prev_hash == hash then
				log.debug("hash matches previous; no update necessary")
				needs_update = false
			end
			hash_f:close()
		end
		profile_f:close()
	end

	if needs_update then
		cmd.exec("mkdir -p -- " .. cache_dir)
		log.info("dumping devshell")
		cmd.exec(strings.join({
			"nix print-dev-env --quiet --profile",
			profile,
			base_dir,
		}, " "))
		log.debug("profile updated")
	end

	profile_f = io.open(profile, "r")
	local dev_env = json.decode(profile_f:read("*a"))
	profile_f:close()

	local ret = {}
	for key, value in pairs(dev_env.variables) do
		if value.type == "exported" then
			ret[key] = value.value
		end
	end

	hash_f = io.open(cached_hash, "w")
	hash_f:write(hash .. "\n")
	hash_f:close()

	return ret
end

return M
