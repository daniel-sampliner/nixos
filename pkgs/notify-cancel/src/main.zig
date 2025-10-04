// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");

const sd_bus = @import("sd_bus");

const scoped = @import("logger").logger;

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
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .err => "<3>",
        .warn => "<4>",
        .info => "<6>",
        .debug => "<7>",
    };

    const prefix2 = if (scope == .default) "" else "(" ++ @tagName(scope) ++ ")";
    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    nosuspend {
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}

test {
    std.testing.log_level = if (config.log_level) |ll| @enumFromInt(ll) else .warn;
    std.testing.refAllDecls(@This());
}

pub fn main() !void {
    const logger = scoped(.default);
    const allocator = std.heap.c_allocator;

    var monitor = sd_bus.Bus{};
    try monitor.init(.monitor);
    defer monitor.free();

    try ready();

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

fn ready() !void {
    const socket_path = std.posix.getenv("NOTIFY_SOCKET") orelse return;
    switch (socket_path[0]) {
        '/' => {},
        '@' => {},
        else => {
            return error.AddressFamilyNotSupported;
        },
    }

    var addr = try std.net.Address.initUnix(socket_path);
    if (addr.un.path[0] == '@') {
        addr.un.path[0] = 0;
    }

    const fd = try std.posix.socket(
        std.posix.AF.UNIX,
        std.posix.SOCK.DGRAM | std.posix.SOCK.CLOEXEC,
        0,
    );
    errdefer std.net.Stream.close(.{ .handle = fd });

    try std.posix.connect(fd, &addr.any, addr.getOsSockLen());
    const stream: std.net.Stream = .{ .handle = fd };

    try stream.writeAll("READY=1");
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
        "cookie: {d}, app: {s}, subject: \"{s}\", body: \"{s}\"",
        .{
            cookie,
            app_buf,
            std.fmt.fmtSliceEscapeLower(std.mem.span(subject_buf)),
            std.fmt.fmtSliceEscapeLower(std.mem.span(body_buf)),
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
    try bus.init(.client);
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
