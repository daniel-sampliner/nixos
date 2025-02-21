// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");

pub const std_options = .{
    .logFn = switch (builtin.mode) {
        .Debug => std.log.defaultLog,
        .ReleaseFast => syslogFn,
        .ReleaseSafe => syslogFn,
        .ReleaseSmall => syslogFn,
    },
};

/// Print log in syslog(3) format. Adapated from std.log.defaultLog.
pub fn syslogFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
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

pub fn main() !void {
    var addr: std.os.linux.sockaddr.un = undefined;
    var addr_len: std.os.linux.socklen_t = @sizeOf(std.os.linux.sockaddr.un);

    const addr_ptr: *std.posix.sockaddr = @ptrCast(&addr);

    try std.posix.getpeername(0, addr_ptr, &addr_len);

    if (addr.family != std.os.linux.AF.UNIX) {
        return error.SocketNotUNIX;
    }

    std.log.debug("addr: {any}", .{addr});
    std.log.debug("addr_len: {d}", .{addr_len});
    if (addr_len <= 2) {
        std.log.err("No peer address on socket FD 0", .{});
        return error.NoPeerAddress;
    }

    const path = addr.path[1 .. addr_len - 2];
    std.log.debug("path: {s}", .{path});

    const key = std.fs.path.basename(path);
    const unit = try if (std.fs.path.dirname(path)) |dir|
        std.fs.path.basename(dir)
    else blk: {
        std.log.err("Could not parse unit from socket path {s}", .{path});
        break :blk error.CantParseUnit;
    };

    std.log.info("Received request for secret {s}/{s}", .{ unit, key });

    const writer = std.io.getStdOut().writer();
    try writer.print("{s}\n", .{key});
}
