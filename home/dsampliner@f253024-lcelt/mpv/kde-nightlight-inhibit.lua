-- SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
--
-- SPDX-License-Identifier: AGPL-3.0-or-later

local ldbus = require("ldbus")

local bus_name = "org.kde.KWin.NightLight"
local object_path = "/org/kde/KWin/NightLight"
local interface_name = "org.kde.KWin.NightLight"

local idle = true
function on_idle_change(name, value)
	idle = value
	handle_nightlight()
end

local paused = true
function on_pause_change(name, value)
	paused = value
	handle_nightlight()
end

local cookie = 0
function handle_nightlight()
	if not (paused or idle) then
		local msg, err = ldbus.message.new_method_call(bus_name, object_path, interface_name, "inhibit")
		if err then
			print("failed to create inhibit message: " .. tostring(err))
			return
		end

		local reply, err = dbus:send_with_reply_and_block(msg)
		if err then
			print("failed to call inhibit: " .. tostring(err))
			return
		end

		local iter = ldbus.message.iter.new()
		if not reply:iter_init(iter) then
			print("inhibit response has no arguments")
			return
		end

		cookie = iter:get_basic()
	else
		local msg, err = ldbus.message.new_method_call(bus_name, object_path, interface_name, "uninhibit")
		if err then
			print("failed to create uninhibit message: " .. tostring(err))
			return
		end

		local iter = ldbus.message.iter.new()
		msg:iter_init_append(iter)
		if not iter:append_basic(cookie, "u") then
			print("failed to append value to message")
			return
		end

		local reply, err = dbus:send_with_reply_and_block(msg)
		if err then
			print("failed to call uninhibit: " .. tostring(err))
			return
		end
	end
end

local err
dbus, err = ldbus.bus.get_private("session")
assert(dbus, tostring(err))

mp.observe_property("idle-active", "bool", on_idle_change)
mp.observe_property("pause", "bool", on_pause_change)
