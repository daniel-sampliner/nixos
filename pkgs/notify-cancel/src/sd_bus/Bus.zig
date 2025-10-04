// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const builtin = @import("builtin");
const std = @import("std");

const c = @import("c.zig");

const Bus = @This();
const Message = @import("Message.zig");
const Error = @import("Error.zig");

const logger = @import("logger").logger(.@"sd_bus.Bus");

sd_bus: ?*c.sd_bus = null,

pub const BusType = enum {
    client,
    monitor,
};

pub fn init(b: *Bus, bt: BusType) !void {
    logger.debug("initializing Bus: {s}", .{@tagName(bt)});

    var r: c_int = undefined;
    r = c.sd_bus_new(&b.sd_bus);
    if (r < 0) {
        logger.err("failed to allocate bus: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusAllocationFailed;
    }
    errdefer b.free();

    r = c.sd_bus_set_description(b.sd_bus, switch (bt) {
        .client => "notify_cancel",
        .monitor => "notify_cancel_monitor",
    });
    if (r < 0) {
        logger.warn("failed to set bus description: {s}", .{Error.fmtSdRetCode(r)});
    }

    switch (bt) {
        .client => {},
        .monitor => {
            r = c.sd_bus_set_monitor(b.sd_bus, @intFromBool(true));
            if (r < 0) {
                logger.err("failed to set monitor mode: {s}", .{Error.fmtSdRetCode(r)});
                return error.DBusSetMonitorFailed;
            }
        },
    }

    r = c.sd_bus_set_bus_client(b.sd_bus, @intFromBool(true));
    if (r < 0) {
        logger.err("failed to set bus client: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusSetBusClientFailed;
    }

    const addr = std.posix.getenvZ("DBUS_SESSION_BUS_ADDRESS") orelse {
        logger.err("DBUS_SESSION_BUS_ADDRESS env var not set", .{});
        return error.DBusMissingEnvVar;
    };
    if (addr.len < 1) {
        logger.err("DBUS_SESSION_BUS_ADDRESS env var not set", .{});
        return error.DBusMissingEnvVar;
    }
    r = c.sd_bus_set_address(b.sd_bus, addr);
    if (r < 0) {
        logger.err(
            "failed to connect to session bus '{s}': {s}",
            .{ std.fmt.fmtSliceEscapeLower(addr), Error.fmtSdRetCode(r) },
        );
        return error.DBusStartFailed;
    }

    r = c.sd_bus_start(b.sd_bus);
    if (r < 0) {
        logger.err(
            "failed to connect to session bus '{s}': {s}",
            .{ std.fmt.fmtSliceEscapeLower(addr), Error.fmtSdRetCode(r) },
        );
        return error.DBusStartFailed;
    }

    switch (bt) {
        .client => {},
        .monitor => {
            var reply = Message{};
            try b.callMethod(
                "org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus.Monitoring",
                "BecomeMonitor",
                &reply,
                "asu",
                .{
                    @as(u32, 2),
                    "type='method_call',interface='org.freedesktop.Notifications',member='Notify'",
                    "type='method_return'",
                    @as(u32, 0),
                },
            );
            defer reply.free();

            try b.waitNameLost();
        },
    }
}

pub fn waitNameLost(b: *Bus) !void {
    const uid = try b.getUniqueName();
    for (0..30) |_| {
        var m = Message{};
        defer m.free();
        const more = try b.process(&m);

        if (!m.isNull()) {
            if (!m.isSignal("org.freedesktop.DBus", "NameLost")) {
                continue;
            }

            const name = try m.readString();
            if (std.mem.eql(u8, uid, name)) {
                logger.debug("monitoring enabled", .{});
                return;
            }
        }

        if (more) {
            continue;
        }

        try b.wait(100 * std.time.us_per_ms);
    }

    return error.DBusNameNotLost;
}

pub fn getUniqueName(b: *Bus) ![]const u8 {
    var buf: [*:0]const u8 = undefined;
    const r = c.sd_bus_get_unique_name(b.sd_bus, &buf);
    if (r < 0) {
        logger.err("failed to get unique name of bus: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusError;
    }
    return std.mem.span(buf);
}

test "monitor" {
    var monitor = Bus{};
    try monitor.init(.monitor);
    defer monitor.free();

    var notification_id = std.atomic.Value(u32).init(0);

    const send_thread = try std.Thread.spawn(.{}, (struct {
        fn func(id: *std.atomic.Value(u32)) !void {
            const l = @import("logger").logger(.@"sd_bus.Bus.test.monitor.thread");

            var client = Bus{};
            try client.init(.client);
            defer client.free();

            var reply = Message{};
            defer reply.free();

            try client.callMethod(
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
                "org.freedesktop.Notifications",
                "Notify",
                &reply,
                "susssasa{sv}i",
                .{
                    "TEST_APP",
                    @as(u32, 0),
                    "",
                    "TEST NOTIFICATION SUMMARY",
                    "TEST NOTIFICATION BODY",
                    @as(i32, 0),
                    @as(u32, 3),
                    "TEST HINT KEY A",
                    "i",
                    @as(i32, 1),
                    "TEST HINT KEY B",
                    "s",
                    "TEST HINT VALUE B",
                    "TEST HINT KEY C",
                    "s",
                    "TEST HINT VALUE C",
                    @as(i32, 30 * std.time.ms_per_s),
                },
            );

            const i = try reply.readUint();
            l.debug("notification id: {d}", .{i});
            id.store(i, .seq_cst);
        }
    }).func, .{&notification_id});
    var send_thread_joined = false;
    errdefer if (!send_thread_joined) send_thread.join();

    var call_cookies = std.AutoHashMap(u64, void).init(std.testing.allocator);
    defer call_cookies.deinit();

    const got = blk: {
        for (0..10) |_| {
            var message = Message{};
            defer message.free();
            const more = try monitor.process(&message);

            if (!message.isNull()) {
                switch (try message.getType()) {
                    .method_call => {
                        const cookie = try message.getCookie();
                        var app: [*:0]u8 = undefined;
                        const nullptr = @as(isize, 0);
                        try message.read(
                            "susss",
                            .{ &app, nullptr, nullptr, nullptr, nullptr },
                        );
                        if (!std.mem.eql(u8, std.mem.span(app), "TEST_APP")) {
                            continue;
                        }

                        try message.skip("as");
                        try message.enterContainer('a', "{sv}");
                        while (!try message.atEnd(false)) {
                            try message.enterContainer('e', "sv");

                            const key = try message.readString();
                            if (!std.mem.eql(u8, key, "TEST HINT KEY B")) {
                                try message.skip("v");
                                try message.exitContainer();
                                continue;
                            }

                            var hint_value: [*:0]u8 = undefined;
                            try message.read("v", .{ "s", &hint_value });
                            if (std.mem.startsWith(u8, std.mem.span(hint_value), "TEST HINT VALUE")) {
                                try call_cookies.put(cookie, {});
                            }
                            try message.exitContainer();
                        }

                        try message.exitContainer();
                    },

                    .method_return => {
                        const reply_cookie = try message.getReplyCookie();
                        if (!call_cookies.remove(reply_cookie)) {
                            continue;
                        }
                        const id = try message.readUint();
                        logger.debug("reply_cookie: {d}, notification_id: {d}", .{ reply_cookie, id });
                        break :blk id;
                    },
                    else => {},
                }
            }

            if (more) {
                continue;
            }

            try monitor.wait(100 * std.time.us_per_ms);
        }
        return error.MissingNotification;
    };

    send_thread.join();
    send_thread_joined = true;
    const want = notification_id.load(.seq_cst);
    defer {
        var client = Bus{};
        if (client.init(.client)) {
            defer client.free();

            client.callMethod(
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
                "org.freedesktop.Notifications",
                "CloseNotification",
                null,
                "u",
                .{want},
            ) catch |err| {
                logger.err("failed to close notification: {}", .{err});
            };
        } else |err| {
            logger.err("failed to initialize dbus client: {}", .{err});
        }
    }

    try std.testing.expectEqual(want, got);
}

pub fn process(b: *Bus, m: *Message) !bool {
    const r = c.sd_bus_process(b.sd_bus, &m.sd_bus_message);
    if (r < 0) {
        logger.err("failed to process bus: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusProcessFailed;
    }
    return r > 0;
}

pub fn wait(b: *Bus, timeout_usec: u64) !void {
    const r = c.sd_bus_wait(b.sd_bus, timeout_usec);
    if (r < 0) {
        logger.err("failed to wait on bus: {s}", .{Error.fmtSdRetCode(r)});
        return error.DBusWaitFailed;
    }
}

test "getUniqueName" {
    var b = Bus{};
    try b.init(.client);
    defer b.free();

    const name = try b.getUniqueName();
    logger.debug("b.getUniqueName(): {s}", .{name});
}

pub fn free(b: *Bus) void {
    _ = c.sd_bus_flush_close_unref(b.sd_bus);
}

pub fn callMethod(
    b: *Bus,
    destination: [:0]const u8,
    path: [:0]const u8,
    interface: [:0]const u8,
    member: [:0]const u8,
    reply: ?*Message,
    dbus_type: [:0]const u8,
    args: anytype,
) !void {
    var err = Error{ .sd_bus_error = blk: {
        var buf = c.sd_bus_error{};
        break :blk &buf;
    } };
    defer err.free();

    logger.debug("trying to call {s}.{s}: {s} {any}", .{ interface, member, dbus_type, args });
    const r = @call(
        .auto,
        c.sd_bus_call_method,
        .{
            b.sd_bus,
            destination,
            path,
            interface,
            member,
            err.sd_bus_error,
            getMessagePtr(reply),
            dbus_type,
        } ++ args,
    );
    if (r < 0) {
        logger.err("failed to call {s}.{s}: {s}", .{ interface, member, err });
        return error.DBusCallFailed;
    }
}

test "callMethod_reply" {
    var b = Bus{};
    try b.init(.client);
    defer b.free();

    const file = try std.fs.openFileAbsolute("/etc/machine-id", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const want = try reader.readBytesNoEof(32);

    var reply = Message{};
    try b.callMethod(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus.Peer",
        "GetMachineId",
        &reply,
        "",
        .{},
    );
    defer reply.free();

    const got = try reply.readString();
    try std.testing.expectEqualStrings(&want, got);
}

test "callMethod_noReply" {
    var b = Bus{};
    try b.init(.client);
    defer b.free();

    try b.callMethod(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus.Peer",
        "GetMachineId",
        null,
        "",
        .{},
    );
}

test "callMethod_bad" {
    var b = Bus{};
    try b.init(.client);
    defer b.free();

    try std.testing.expectError(
        error.DBusCallFailed,

        b.callMethod(
            "example.test",
            "/example/test",
            "example.test",
            "method",
            null,
            "",
            .{},
        ),
    );
}

pub fn newMethodCall(
    b: *Bus,
    m: *Message,
    destination: [:0]const u8,
    path: [:0]const u8,
    interface: [:0]const u8,
    member: [:0]const u8,
) !void {
    const r = c.sd_bus_message_new_method_call(
        b.sd_bus,
        &m.sd_bus_message,
        destination,
        path,
        interface,
        member,
    );
    if (r < 0) {
        logger.err("failed to create {s}.{s} message: {s}", .{ interface, member, Error.fmtSdRetCode(r) });
        return error.DBusAllocationFailed;
    }
}

pub fn call(
    b: *Bus,
    message: *Message,
    timeout_usec: u64,
    reply: ?*Message,
) !void {
    var err = Error{ .sd_bus_error = blk: {
        var buf = c.sd_bus_error{};
        break :blk &buf;
    } };

    const r = c.sd_bus_call(
        b.sd_bus,
        message.sd_bus_message,
        timeout_usec,
        err.sd_bus_error,
        getMessagePtr(reply),
    );
    if (r < 0) {
        logger.err("failed to call {s}.{s}: {s}", .{ message.getInterface(), message.getMember(), err });
        return error.DBusCallFailed;
    }

    defer err.free();
}

fn getMessagePtr(m: ?*Message) *allowzero ?*c.sd_bus_message {
    return if (m) |mm|
        &mm.sd_bus_message
    else
        @ptrFromInt(0);
}
