// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

pub const struct_sd_bus = opaque {};
pub const sd_bus = struct_sd_bus;
pub const struct_sd_bus_message = opaque {};
pub const sd_bus_message = struct_sd_bus_message;

pub const sd_bus_error = extern struct {
    name: ?[*:0]const u8 = null,
    message: ?[*:0]const u8 = null,
    _need_free: c_int = 0,
};

pub const SD_BUS_MESSAGE_METHOD_CALL: c_int = 1;
pub const SD_BUS_MESSAGE_METHOD_RETURN: c_int = 2;
pub const SD_BUS_MESSAGE_METHOD_ERROR: c_int = 3;
pub const SD_BUS_MESSAGE_SIGNAL: c_int = 4;

pub extern fn sd_bus_call(bus: ?*sd_bus, m: ?*sd_bus_message, usec: u64, ret_error: *sd_bus_error, reply: *allowzero ?*sd_bus_message) c_int;
pub extern fn sd_bus_call_method(bus: ?*sd_bus, destination: [*:0]const u8, path: [*:0]const u8, interface: [*:0]const u8, member: [*:0]const u8, ret_error: ?*sd_bus_error, reply: *allowzero ?*sd_bus_message, types: [*:0]const u8, ...) c_int;
pub extern fn sd_bus_default_user(ret: *?*sd_bus) c_int;
pub extern fn sd_bus_flush_close_unref(bus: ?*sd_bus) ?*sd_bus;
pub extern fn sd_bus_get_unique_name(bus: ?*sd_bus, unique: *[*:0]const u8) c_int;
pub extern fn sd_bus_new(ret: *?*sd_bus) c_int;
pub extern fn sd_bus_open_user_with_description(ret: *?*sd_bus, description: [*:0]const u8) c_int;
pub extern fn sd_bus_open_with_description(ret: *?*sd_bus, description: [*:0]const u8) c_int;
pub extern fn sd_bus_process(bus: ?*sd_bus, r: *?*sd_bus_message) c_int;
pub extern fn sd_bus_set_address(bus: ?*sd_bus, address: [*:0]const u8) c_int;
pub extern fn sd_bus_set_bus_client(bus: ?*sd_bus, b: c_int) c_int;
pub extern fn sd_bus_set_description(bus: ?*sd_bus, description: [*:0]const u8) c_int;
pub extern fn sd_bus_set_monitor(bus: ?*sd_bus, b: c_int) c_int;
pub extern fn sd_bus_start(bus: ?*sd_bus) c_int;
pub extern fn sd_bus_wait(bus: ?*sd_bus, timeout_usec: u64) c_int;

pub extern fn sd_bus_error_free(e: *sd_bus_error) void;
pub extern fn sd_bus_error_is_set(e: *const sd_bus_error) c_int;

pub extern fn sd_bus_message_append_basic(m: ?*sd_bus_message, @"type": u8, p: ?*const anyopaque) c_int;
pub extern fn sd_bus_message_at_end(m: ?*sd_bus_message, complete: c_int) c_int;
pub extern fn sd_bus_message_close_container(m: ?*sd_bus_message) c_int;
pub extern fn sd_bus_message_enter_container(m: ?*sd_bus_message, @"type": u8, contents: [*:0]const u8) c_int;
pub extern fn sd_bus_message_exit_container(m: ?*sd_bus_message) c_int;
pub extern fn sd_bus_message_get_cookie(m: ?*sd_bus_message, cookie: *u64) c_int;
pub extern fn sd_bus_message_get_interface(m: ?*sd_bus_message) [*:0]const u8;
pub extern fn sd_bus_message_get_member(m: ?*sd_bus_message) [*:0]const u8;
pub extern fn sd_bus_message_get_reply_cookie(m: ?*sd_bus_message, cookie: *u64) c_int;
pub extern fn sd_bus_message_get_type(m: ?*sd_bus_message, @"type": *u8) c_int;
pub extern fn sd_bus_message_is_method_call(m: ?*sd_bus_message, interface: [*:0]const u8, member: [*:0]const u8) c_int;
pub extern fn sd_bus_message_is_signal(m: ?*sd_bus_message, interface: ?[*:0]const u8, member: ?[*:0]const u8) c_int;
pub extern fn sd_bus_message_new_method_call(bus: ?*sd_bus, m: *?*sd_bus_message, destination: [*:0]const u8, path: [*:0]const u8, interface: [*:0]const u8, member: [*:0]const u8) c_int;
pub extern fn sd_bus_message_open_container(m: ?*sd_bus_message, @"type": u8, contents: [*:0]const u8) c_int;
pub extern fn sd_bus_message_read(m: ?*sd_bus_message, types: [*:0]const u8, ...) c_int;
pub extern fn sd_bus_message_read_basic(m: ?*sd_bus_message, @"type": u8, p: ?*anyopaque) c_int;
pub extern fn sd_bus_message_skip(m: ?*sd_bus_message, types: [*:0]const u8) c_int;
pub extern fn sd_bus_message_unref(m: ?*sd_bus_message) ?*sd_bus_message;
