// SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");

const config = @import("config");
const scoped = @import("logger").logger;
const sd_bus = @import("sd_bus");

pub const std_options: std.Options = .{
    .log_level = if (config.log_level) |ll| @enumFromInt(ll) else std.log.default_level,
    .logFn = switch (builtin.is_test) {
        true => std.log.defaultLog,
        false => switch (builtin.mode) {
            .Debug => std.log.defaultLog,
            .ReleaseFast => syslogFn,
            .ReleaseSafe => syslogFn,
            .ReleaseSmall => syslogFn,
        },
    },
};

/// Print log in syslog(3) format. Adapated from std.log.defaultLog.
pub fn syslogFn(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    const io = std.Options.debug_io;
    const prev = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(prev);

    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer).terminal();
    defer std.debug.unlockStderr();

    return syslogFnFileTerminal(level, scope, format, args, stderr) catch {};
}

/// Adapted from std.log.defaultLogFileTerminal.
pub fn syslogFnFileTerminal(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
    t: std.Io.Terminal,
) std.Io.Writer.Error!void {
    try t.writer.writeAll(switch (level) {
        .err => "<3>",
        .warn => "<4>",
        .info => "<6>",
        .debug => "<7>",
    });
    if (scope != .default) try t.writer.print("({t})", .{scope});
    try t.writer.writeAll(": ");
    try t.writer.print(format ++ "\n", args);
}

test {
    std.testing.log_level = if (config.log_level) |ll| @enumFromInt(ll) else .warn;
    std.testing.refAllDecls(@This());
}

pub fn main(init: std.process.Init) !void {
    const logger = scoped(.default);
    const allocator = std.heap.c_allocator;

    const dbus_addr = blk: {
        const env = "DBUS_SESSION_BUS_ADDRESS";
        const msg = "{s} env var not set";
        const addr = init.minimal.environ.getPosix(env) orelse {
            logger.err(msg, .{env});
            return error.DBusMissingEnvVar;
        };
        if (addr.len < 1) {
            logger.err(msg, .{env});
            return error.DBusMissingEnvVar;
        }
        break :blk addr;
    };

    var monitor = sd_bus.Bus{};
    try monitor.init(.monitor, dbus_addr);
    defer monitor.free();

    if (init.environ_map.get("NOTIFY_SOCKET")) |s| try ready(init.io, s);

    var call_cookies = std.AutoHashMap(u64, void).init(allocator);
    defer call_cookies.deinit();

    while (true) {
        errdefer if (config.use_debugger) @breakpoint();

        var message = sd_bus.Message{};
        defer message.free();

        const more = try monitor.process(&message);
        if (!message.isNull()) {
            switch (try message.getType()) {
                .method_call => handleCall(
                    &message,
                    &call_cookies,
                    config.app_filter,
                ) catch |err| logger.err("{}", .{err}),

                .method_return => handleReturn(
                    &message,
                    &call_cookies,
                    dbus_addr,
                ) catch |err| {
                    logger.err("{}", .{err});
                    switch (err) {
                        error.DBusCallFailed => return err,
                        else => {},
                    }
                },

                else => {},
            }
        }

        if (more) {
            continue;
        }

        try monitor.wait(std.math.maxInt(u64));
    }
}

const ready_msg = "READY=1" ++ "\n";

fn ready(io: std.Io, socket_path: []const u8) !void {
    const path = switch (socket_path[0]) {
        '/', 0 => socket_path,
        '@' => blk: {
            var buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
            var p = buf[0..socket_path.len];
            p[0] = 0;
            @memcpy(p[1..], socket_path[1..]);
            std.log.debug(
                "{f} => {f}",
                .{
                    std.ascii.hexEscape(socket_path, .upper),
                    std.ascii.hexEscape(p, .upper),
                },
            );
            break :blk p;
        },
        else => return error.AddressFamilyNotSupported,
    };

    const addr: std.Io.net.UnixAddress = try .init(path[0..socket_path.len]);
    const stream = try addr.connect(io, .{ .mode = .dgram });
    errdefer stream.close(io);

    var w = stream.writer(io, &.{});
    try w.interface.writeAll(ready_msg);
}

test "ready" {
    const io = std.testing.io;
    const logger = scoped(.ready);

    const sock_path = blk: {
        var random_bytes: [12]u8 = undefined;
        io.random(&random_bytes);
        var suffix: [std.base64.url_safe.Encoder.calcSize(random_bytes.len)]u8 = undefined;
        _ = std.base64.url_safe.Encoder.encode(&suffix, &random_bytes);
        break :blk try std.fmt.allocPrint(std.testing.allocator, "\x00notify-cancel-test.{s}", .{&suffix});
    };
    defer std.testing.allocator.free(sock_path);
    logger.info("path: {f}", .{std.ascii.hexEscape(sock_path, .upper)});

    const addr: std.Io.net.UnixAddress = try .init(sock_path);
    var server = try addr.bind(io, .{ .mode = .dgram });
    defer server.close(io);

    var client_task = try io.concurrent(ready, .{ io, sock_path });
    defer client_task.cancel(io) catch |err|
        scoped(.@"ready.client_task").err("cancel err: {}", .{err});

    var buf: [ready_msg.len]u8 = undefined;
    const msg = try server.receive(io, &buf);
    const got = msg.data;

    try std.testing.expectEqualStrings(ready_msg, got);

    try client_task.await(io);
}

fn testReadyRead(io: std.Io, server: *std.Io.net.Server, buf: *[]u8) error{Canceled}!void {
    const logger = scoped(.testReadyRead);

    const stream = server.accept(io) catch |err| {
        logger.err("failed to accept: {}", .{err});
        return error.Canceled;
    };

    defer stream.close(io);
    defer stream.shutdown(io, .recv) catch {};
    stream.shutdown(io, .send) catch {};

    var r = stream.reader(io, buf.*);
    const msg = r.interface.takeDelimiter('\n') catch |err| {
        logger.err("failed to read: {}", .{err});
        return error.Canceled;
    };
    buf.len = if (msg) |m| m.len else 0;
}

fn testReadyWrite(io: std.Io, sock_path: []const u8) error{Canceled}!void {
    const logger = scoped(.testReadyWrite);

    ready(io, sock_path) catch |err| {
        logger.err("{}", .{err});
        return error.Canceled;
    };
}

fn handleCall(
    message: *sd_bus.Message,
    cookies: *std.AutoHashMap(u64, void),
    app: []const u8,
) !void {
    const logger = scoped(.handleCall);
    const cookie = try message.getCookie();
    const nullptr = @as(isize, 0);

    var app_buf: [*:0]u8 = undefined;
    var subject_buf: [*:0]u8 = undefined;
    var body_buf: [*:0]u8 = undefined;

    try message.read(
        "susss",
        .{
            &app_buf,
            nullptr,
            nullptr,
            &subject_buf,
            &body_buf,
        },
    );

    if (!std.mem.eql(u8, std.mem.span(app_buf), app)) {
        return;
    }

    var should_close = false;

    try message.skip("as");
    try message.enterContainer('a', "{sv}");
    while (!try message.atEnd(false)) {
        try message.enterContainer('e', "sv");

        const key = try message.readString();
        if (!std.mem.eql(u8, key, "x-kde-origin-name")) {
            try message.skip("v");
            try message.exitContainer();
            continue;
        }

        var origin: [*:0]u8 = undefined;
        try message.read("v", .{ "s", &origin });
        should_close = std.mem.startsWith(u8, std.mem.span(origin), " ");
        try message.exitContainer();
    }
    try message.exitContainer();

    if (!should_close) {
        return;
    }

    logger.debug(
        "cookie: {d}, app: {s}, subject: \"{f}\", body: \"{f}\"",
        .{
            cookie,
            app_buf,
            std.ascii.hexEscape(std.mem.span(subject_buf), .lower),
            std.ascii.hexEscape(std.mem.span(body_buf), .lower),
        },
    );

    try cookies.put(cookie, {});
    if (builtin.mode == .Debug) {
        var iter = cookies.keyIterator();
        while (iter.next()) |k| {
            logger.debug("cookie: {d}", .{k.*});
        }
    }
}

fn handleReturn(
    message: *sd_bus.Message,
    cookies: *std.AutoHashMap(u64, void),
    dbus_addr: [:0]const u8,
) !void {
    const logger = scoped(.handleReturn);
    const reply_cookie = try message.getReplyCookie();
    if (builtin.mode == .Debug) {
        var iter = cookies.keyIterator();
        while (iter.next()) |k| {
            logger.debug("cookie: {d}", .{k.*});
        }
    }

    if (!cookies.remove(reply_cookie)) {
        return;
    }
    const id = try message.readUint();
    logger.debug("reply_cookie: {d}, id: {d}", .{ reply_cookie, id });

    var bus = sd_bus.Bus{};
    try bus.init(.client, dbus_addr);
    defer bus.free();

    try bus.callMethod(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications",
        "CloseNotification",
        null,
        "u",
        .{id},
    );
}
