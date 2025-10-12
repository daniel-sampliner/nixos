-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local cmd = require("cmd")
local file = require("file")
local json = require("json")
local strings = require("strings")

local file_extra = require("file_extra")
local log = require("log")

local M = {}

function M.get_mise_config(options)
	local mise_configs = json.decode(cmd.exec("mise config ls --json"))
	for _, mise_config in ipairs(mise_configs) do
		local dir = file_extra.dirname(mise_config.path)
		local _, f = next(options.watch_files)
		local devshell = file.join_path(dir, f)
		if file_extra.exists(devshell) then
			return dir, mise_config.path
		end
	end

	return nil, nil
end

function M.get_hash(options, base_dir)
	local files = options.watch_files
	local hash_cmd = options.hash_cmd or "xxhsum -H3"

	if not files or next(files) == nil then
		return nil
	end

	local comm = strings.join({
		"echo",
		"'" .. base_dir .. "'",
		"|",
		"cat -",
		strings.join(files, " "),
		"|",
		hash_cmd,
	}, " ")
	log.debug("running command: " .. comm)
	local output = cmd.exec(comm, { cwd = base_dir })
	local hash = strings.split(output, " ")[1]
	return hash
end

function M.dev_env(options)
	if not options.watch_files then
		options.watch_files = { "flake.lock", "flake.nix" }
	end

	local needs_update = true

	local base_dir, mise_config = M.get_mise_config(options)

	if not base_dir then
		log.error("Could not determine base_dir")
		return
	end
	log.debug("base_dir: " .. base_dir)

	if not mise_config then
		log.error("Could not determine mise_config")
		return
	end
	log.debug("mise_config: " .. mise_config)

	local cache_dir = file.join_path(base_dir, ".mise-nix-devshell")
	local profile = file.join_path(cache_dir, "dev-env")
	local cached_hash = file.join_path(cache_dir, "hash")
	local hash = M.get_hash(options, base_dir)

	if file_extra.exists(profile) then
		log.debug("profile exists")
		local comm = ("nix profile wipe-history --quiet --profile " .. profile)
		log.debug("running command: " .. comm)
		cmd.exec(comm, { cwd = base_dir })

		local hash_f = io.open(cached_hash, "r")
		if hash_f then
			log.debug("previous hash exists")
			prev_hash = hash_f:read("*l")
			hash_f:close()

			if hash and prev_hash == hash then
				log.debug("hash matches previous; no update necessary")
				needs_update = false
			end
		end
	end

	if needs_update then
		cmd.exec("mkdir -p -- " .. cache_dir, { cwd = base_dir })
		log.info("dumping devshell")

		local comm = strings.join({
			"nix print-dev-env --quiet --no-write-lock-file --profile",
			profile,
			(options.args or "'" .. base_dir .. "'"),
		}, " ")
		log.debug("running command: " .. comm)
		cmd.exec(comm, { cwd = base_dir })

		cmd.exec(strings.join({ "touch", mise_config }, " "), { cwd = base_dir })
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
