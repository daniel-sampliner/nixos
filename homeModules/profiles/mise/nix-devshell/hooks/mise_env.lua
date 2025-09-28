-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local strings = require("strings")

local log = require("log")
local nix = require("nix")

local discard_vars = {
	["CONFIG_SHELL"] = true,
	["DETERMINISTIC_BUILD"] = true,
	["DETERMINITSTIC_BUILD"] = true,
	["HOME"] = true,
	["HOST_PATH"] = true,
	["NIX_BUILD_CORES"] = true,
	["NIX_BUILD_TOP"] = true,
	["NIX_CFLAGS_COMPILE"] = true,
	["NIX_ENFORCE_NO_NATIVE"] = true,
	["NIX_ENFORCE_PURITY"] = true,
	["NIX_LDFLAGS"] = true,
	["NIX_LOG_FD"] = true,
	["NIX_STORE"] = true,
	["OLDPWD"] = true,
	["PATH"] = true,
	["PYTHONHASHSEED"] = true,
	["PYTHONNOUSERSITE"] = true,
	["SHELL"] = true,
	["SOURCE_DATE_EPOCH"] = true,
	["TEMP"] = true,
	["TEMPDIR"] = true,
	["TERM"] = true,
	["TMP"] = true,
	["TMPDIR"] = true,
	["TZ"] = true,
	["_PYTHON_HOST_PLATFORM"] = true,
	["_PYTHON_SYSCONFIGDATA_NAME"] = true,
	["__structuredAttrs"] = true,
	["buildInputs"] = true,
	["buildPhase"] = true,
	["builder"] = true,
	["cmakeFlags"] = true,
	["configureFlags"] = true,
	["depsBuildBuild"] = true,
	["depsBuildBuildPropagated"] = true,
	["depsBuildTarget"] = true,
	["depsBuildTargetPropagated"] = true,
	["depsHostHost"] = true,
	["depsHostHostPropagated"] = true,
	["depsTargetTarget"] = true,
	["depsTargetTargetPropagated"] = true,
	["doCheck"] = true,
	["doInstallCheck"] = true,
	["dontAddDisableDepTrack"] = true,
	["mesonFlags"] = true,
	["nativeBuildInputs"] = true,
	["out"] = true,
	["outputs"] = true,
	["patches"] = true,
	["phases"] = true,
	["preferLocalBuild"] = true,
	["propagatedBuildInputs"] = true,
	["propagatedNativeBuildInputs"] = true,
	["shell"] = true,
	["shellHook"] = true,
	["stdenv"] = true,
	["strictDeps"] = true,
	["system"] = true,
}

local pathlike_vars = {
	["PYTHONPATH"] = true,
	["XDG_CONFIG_DIRS"] = true,
	["XDG_DATA_DIRS"] = true,
}

function PLUGIN:MiseEnv(ctx)
	if not ctx.options.enable then
		return {}
	end

	local env = nix.dev_env(ctx.options)
	local val
	local ret = {}
	for key, value in pairs(env) do
		if not discard_vars[key] then
			if pathlike_vars[key] then
				val = os.getenv(key)
				if val then
					value = strings.join({ value, val }, ":")
				end
			end
			log.debug(key .. "=" .. value)
			ret[#ret + 1] = { key = key, value = value }
		end
	end

	return ret
end
