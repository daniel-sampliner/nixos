// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const c = @import("c.zig");

const Error = @import("Error.zig");
const Message = @This();

const logger = @import("logger").logger(.@"sd_bus.Message");

sd_bus_message: ?*c.sd_bus_message = null,

pub const Type = enum(c_int) {
    method_call = c.SD_BUS_MESSAGE_METHOD_CALL,
    method_return = c.SD_BUS_MESSAGE_METHOD_RETURN,
    method_error = c.SD_BUS_MESSAGE_METHOD_ERROR,
    signal = c.SD_BUS_MESSAGE_SIGNAL,
    unknown,
    _,
};

pub fn free(m: Message) void {
    _ = c.sd_bus_message_unref(m.sd_bus_message);
}

pub fn getInterface(m: *Message) []const u8 {
    return std.mem.span(c.sd_bus_message_get_interface(m.sd_bus_message));
}

pub fn getMember(m: *Message) []const u8 {
    return std.mem.span(c.sd_bus_message_get_member(m.sd_bus_message));
}

pub fn getCookie(m: *Message) !u64 {
    var buf: u64 = undefined;
    const r = c.sd_bus_message_get_cookie(m.sd_bus_message, &buf);
    if (r < 0) {
        logger.err("failed to get cookie: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusMessageGetCookieFailed;
    }
    return buf;
}

pub fn getReplyCookie(m: *Message) !u64 {
    var buf: u64 = undefined;
    const r = c.sd_bus_message_get_reply_cookie(m.sd_bus_message, &buf);
    if (r < 0) {
        logger.err("failed to get reply cookie: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusMessageGetReplyCookieFailed;
    }
    return buf;
}

pub fn isNull(m: *Message) bool {
    return if (m.sd_bus_message) |_| false else true;
}

pub fn isSignal(
    m: *Message,
    interface: ?[:0]const u8,
    member: ?[:0]const u8,
) bool {
    return c.sd_bus_message_is_signal(
        m.sd_bus_message,
        interface orelse null,
        member orelse null,
    ) == 1;
}

pub fn getType(m: *Message) !Message.Type {
    var buf = Message.Type.unknown;
    const r = c.sd_bus_message_get_type(m.sd_bus_message, @ptrCast(&buf));
    if (r < 0) {
        logger.err("failed to get type of message: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusMessageGetTypeFailed;
    }
    return switch (buf) {
        .method_call => |t| t,
        .method_return => |t| t,
        .method_error => |t| t,
        .signal => |t| t,
        .unknown => |t| t,
        else => error.DBusUnknownMessageType,
    };
}

pub fn openContainer(m: *Message, dbus_type: u8, contents: [*:0]const u8) !void {
    const r = c.sd_bus_message_open_container(m.sd_bus_message, dbus_type, contents);
    if (r < 0) {
        logger.err("failed to create {s} message: {s}", .{ m.getMember(), Error.fmtSdRetCode(r) });
        return error.DBusAllocationFailed;
    }
}

pub fn closeContainer(m: *Message) !void {
    const r = c.sd_bus_message_close_container(m.sd_bus_message);
    if (r < 0) {
        logger.err("failed to close {s} message: {s}", .{ m.getMember(), Error.fmtSdRetCode(r) });
        return error.DBusAllocationFailed;
    }
}

pub fn appendString(m: *Message, s: [:0]const u8) !void {
    const r = c.sd_bus_message_append_basic(m.sd_bus_message, 's', s.ptr);
    if (r < 0) {
        logger.err("failed to append string to {s} message: {s}", .{ m.getMember(), Error.fmtSdRetCode(r) });
        return error.DBusAllocationFailed;
    }
}

pub fn appendUint(m: *Message, u: u32) !void {
    const r = c.sd_bus_message_append_basic(m.sd_bus_message, 'u', &u);
    if (r < 0) {
        logger.err("failed to append uint to {s} message: {s}", .{ m.getMember(), Error.fmtSdRetCode(r) });
        return error.DBusAllocationFailed;
    }
}

pub fn readString(m: *Message) ![]const u8 {
    var buf: [*:0]const u8 = undefined;
    const r = c.sd_bus_message_read_basic(m.sd_bus_message, 's', @ptrCast(@alignCast(&buf)));
    if (r < 0) {
        logger.err("failed to read from message: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusMessageReadFailed;
    }
    return std.mem.span(buf);
}

pub fn readUint(m: *Message) !u32 {
    var buf: u32 = undefined;
    const r = c.sd_bus_message_read_basic(m.sd_bus_message, 'u', &buf);
    if (r < 0) {
        logger.err("failed to read from message: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusMessageReadFailed;
    }
    return buf;
}

pub fn read(m: *Message, dbus_types: [:0]const u8, ptrs: anytype) !void {
    const r = @call(
        .auto,
        c.sd_bus_message_read,
        .{ m.sd_bus_message, dbus_types } ++ ptrs,
    );
    if (r < 0) {
        logger.err("failed to read from message: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusMessageReadFailed;
    }
}
